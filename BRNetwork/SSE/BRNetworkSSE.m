//
//  BRNetworkSSE.m
//  BRNetworkDemo
//
//  Created by renbo on 2025/3/21.
//  Copyright © 2018年 irenb. All rights reserved.
//

#import "BRNetworkSSE.h"

#ifdef __OBJC__

#ifdef DEBUG
// 日志输出宏定义
#define BRApiLog(FORMAT, ...) fprintf(stderr, "%s:[第%d行]\t%s\n", [[[NSString stringWithUTF8String: __FILE__] lastPathComponent] UTF8String], __LINE__, [[NSString stringWithFormat: FORMAT, ## __VA_ARGS__] UTF8String]);
#else
#define BRApiLog(FORMAT, ...)
#endif

#endif

@interface BRNetworkSSE ()<NSURLSessionDataDelegate>
// 网络会话对象，用于管理网络请求
@property (nonatomic, strong) NSURLSession *session;
// 当前的数据请求任务
@property (nonatomic, strong) NSURLSessionDataTask *dataTask;
// 消息缓冲区，用于累积接收到的分块数据直到形成完整消息
@property (nonatomic, strong) NSMutableString *messageBuffer;

@end

@implementation BRNetworkSSE

#pragma mark - 初始化方法
- (instancetype)init {
    if (self = [super init]) {
        // 设置请求超时时间(默认20秒)
        self.timeoutInterval = 20.0f;
        
        // 使用默认会话配置
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        // 创建会话对象，设置代理和回调队列(主队列)
        self.session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return self;
}

#pragma mark - 公共方法
/// 开始网络请求
- (void)startRequest {
    // 对于GET请求，将参数拼接到URL后面
    NSString *requestUrl = self.url;
    // 1.创建请求URL
    NSURL *requestURL = [NSURL URLWithString:requestUrl];
    if (!requestURL) {
        NSLog(@"无效的URL: %@", requestUrl);
        return;
    }
    // 2.创建可变的网络请求对象
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL];
    request.HTTPMethod = self.method;
    // 3.设置HTTP头
    if (self.headers) {
        [self.headers enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
            [request setValue:value forHTTPHeaderField:key];
        }];
    }
    // 4. 对于POST请求，设置请求体(JSON格式)
    if (self.params && [self.method isEqualToString:@"POST"]) {
        NSError *jsonError = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self.params options:0 error:&jsonError];
        if (!jsonError) {
            [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            request.HTTPBody = jsonData;
        } else {
            NSLog(@"JSON 序列化失败: %@", jsonError.localizedDescription);
        }
    }
    BRApiLog(@"\n[%@]url：%@\nheader：\n%@\nparams：\n%@\n\n", self.method, self.url, self.headers, self.params);
    // 设置请求超时时间(20秒)
    request.timeoutInterval = self.timeoutInterval;
    // 5.创建加载数据任务（处理网络请求，通过设置代理来接收数据）
    self.dataTask = [self.session dataTaskWithRequest:request];
    // 清空缓冲区
    self.messageBuffer = [NSMutableString new];  // 直接创建新缓冲区
    // 6.启动任务
    [self.dataTask resume];
}

/// 取消当前请求
- (void)cancelRequest {
    // 取消数据任务
    [self.dataTask cancel];
    self.dataTask = nil;
    
    // 清空缓冲区
    self.messageBuffer = nil;
}

#pragma mark - 私有方法
/// 处理接收到的原始数据(可能不完整)
/// @param result 接收到的字符串数据
- (void)onMessage:(NSString *)result {
    if (!result || result.length == 0) {
        return;
    }
    // 将新数据追加到缓冲区
    [self.messageBuffer appendString:result];
    
    // 循环处理缓冲区中的完整SSE格式数据
    while (self.messageBuffer.length > 0) {
        // 查找消息分隔符(通常是双换行符作为单个完整SSE消息的结束分隔符，如果找不到双换行符就找单换行符)
        NSRange singleNewline = [self.messageBuffer rangeOfString:@"\n"];
        NSRange doubleNewline = [self.messageBuffer rangeOfString:@"\n\n"];
        
        NSRange range;
        if (doubleNewline.location != NSNotFound) {
            range = doubleNewline;
        } else if (singleNewline.location != NSNotFound) {
            range = singleNewline;
        } else {
            NSLog(@"==没有完整消息，等待更多数据==");
            break;
        }
        
        // 提取单个完整的SSE消息(分隔符之前的内容)
        NSString *completeMessage = [self.messageBuffer substringToIndex:range.location];
        // 从缓冲区中移除已处理的消息(包括分隔符)
        [self.messageBuffer deleteCharactersInRange:NSMakeRange(0, range.location + range.length)];
        // 处理单个完整的SSE消息（分块数据）
        [self processSSEMessage:completeMessage];
    }
}

/// 处理单个完整的SSE消息（分块数据）
/// @param message 完整的SSE消息字符串
- (void)processSSEMessage:(NSString *)message {
    if (!message || message.length == 0) {
        return;
    }
    // 按行分割消息，得到行数组
    NSArray *lines = [message componentsSeparatedByString:@"\n"];
    NSString *event = nil;
    NSMutableString *dataContent = [NSMutableString string];
    
    // 逐行解析消息内容
    for (NSString *line in lines) {
        if ([line hasPrefix:@"event:"]) {
            // 解析事件类型(去除前缀和首尾空格)
            event = [[line substringFromIndex:6] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        } else if ([line hasPrefix:@"data:"]) {
            // 标准SSE数据行(带"data:"前缀)
            NSString *dataLine = [[line substringFromIndex:5] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if (dataContent.length > 0) {
                [dataContent appendString:@"\n"];  // 多行data字段间的换行
            }
            [dataContent appendString:dataLine];
        } else if (line.length > 0 && ![line hasPrefix:@":"]) {
            // 非标准数据行(不带前缀的纯数据)
            [dataContent appendFormat:@"%@\n", [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
        }
    }
    
    // 如果有数据内容，进行解析并回调
    if (dataContent.length > 0) {
        id parsedData = [self parseData:[dataContent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
        if (self.onMessageBlock) {
            // 线程安全，确保回调在主线程执行
            dispatch_async(dispatch_get_main_queue(), ^{
                self.onMessageBlock(event, parsedData);
            });
        }
    }
}

/// 解析数据内容，尝试解析为JSON，失败则返回原始字符串
/// @param dataString 要解析的数据字符串
/// @return 解析后的对象(NSDictionary/NSArray)或原始字符串
- (id)parseData:(NSString *)dataString {
    if (!dataString || dataString.length == 0) {
        return nil;
    }
    // 尝试解析为JSON
    NSError *jsonError = nil;
    NSData *jsonData = [dataString dataUsingEncoding:NSUTF8StringEncoding];
    id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&jsonError];
    if (!jsonError) {
        return jsonObject;
    }
    
    // JSON解析失败，返回原始字符串
    NSLog(@"JSON parsing error: %@", jsonError.localizedDescription);
    return dataString;
}

#pragma mark - 请求状态回调
/// 请求完成处理
- (void)onComplete {
    // 取消请求并清空资源
    [self cancelRequest];
    
    // 执行完成回调(主线程)
    if (self.onCompleteBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.onCompleteBlock();
        });
    }
}

/// 请求失败处理
- (void)onError:(NSError *)error {
    // 取消请求并清空资源
    [self cancelRequest];
    
    // 执行错误回调(主线程)
    if (self.onErrorBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // 区分取消错误和其他错误
            if (error.code == NSURLErrorCancelled) {
                self.onErrorBlock([NSError errorWithDomain:@"BRSSEErrorDomain" code:1001 userInfo:@{NSLocalizedDescriptionKey:@"连接被主动取消"}]);
            } else {
                self.onErrorBlock(error);
            }
        });
    }
}

#pragma mark - NSURLSessionDataDelegate
/// 1.接收到服务器响应数据时调用(可能多次调用)
/// 每次收到数据都会触发此方法
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    // 将接收到的数据转换为字符串(UTF-8编码)
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (!dataString) {
        NSLog(@"收到非UTF-8编码数据");
        NSError *error = [NSError errorWithDomain:@"BRSSEErrorDomain" code:1002 userInfo:@{NSLocalizedDescriptionKey: @"收到非UTF-8编码数据"}];
        [self onError:error];
        return;
    }
    
    BRApiLog(@"===收到SSE数据===\n%@", dataString);
    
    // 处理接收到的数据
    [self onMessage:dataString];
}

/// 2.请求完成或失败时调用
/// 无论是成功完成还是失败都会触发此方法
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error) {
        // 请求失败处理
        if (error.code == NSURLErrorCancelled) {
            // 特殊处理网络中断情况
            NSLog(@"SSE连接被取消");
        } else {
            NSLog(@"SSE连接失败: %@", error.localizedDescription);
            [self onError:error];
        }
    } else {
        // 请求成功完成处理
        NSLog(@"SSE连接完成");
        [self onComplete];
    }
}

/// 消息缓冲区懒加载
- (NSMutableString *)messageBuffer {
    if (!_messageBuffer) {
        _messageBuffer = [[NSMutableString alloc]init];
    }
    return _messageBuffer;
}

@end
