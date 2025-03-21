//
//  BRNetworkSSE.m
//  BRNetworkDemo
//
//  Created by renbo on 2025/3/21.
//  Copyright © 2018年 irenb. All rights reserved.
//

#import "BRNetworkSSE.h"

@interface BRNetworkSSE ()<NSURLSessionDataDelegate>
// 会话对象
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLSessionDataTask *dataTask;

@end

@implementation BRNetworkSSE

- (instancetype)init {
    if (self = [super init]) {
        // 默认会话模式
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        // 通过设置配置、代理、队列来创建会话对象
        self.session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return self;
}

#pragma mark - Public Method
/// GET请求方法
+ (void)getWithUrl:(NSString *)url
            params:(nullable NSDictionary *)params
           headers:(nullable NSDictionary *)headers
    onMessageBlock:(BROnMessageBlock)onMessageBlock
      onErrorBlock:(BROnErrorBlock)onErrorBlock {
    BRNetworkSSE *req = [[BRNetworkSSE alloc] init];
    req.url = url;
    req.method = @"GET";
    req.params = params;
    req.headers = headers;
    req.onMessageBlock = onMessageBlock;
    req.onErrorBlock = onErrorBlock;
    [req startRequest];
}

/// POST请求方法
+ (void)postWithUrl:(NSString *)url
             params:(nullable NSDictionary *)params
            headers:(nullable NSDictionary *)headers
     onMessageBlock:(BROnMessageBlock)onMessageBlock
       onErrorBlock:(BROnErrorBlock)onErrorBlock {
    BRNetworkSSE *req = [[BRNetworkSSE alloc] init];
    req.url = url;
    req.method = @"POST";
    req.params = params;
    req.headers = headers;
    req.onMessageBlock = onMessageBlock;
    req.onErrorBlock = onErrorBlock;
    [req startRequest];
}

/// 开始请求
- (void)startRequest {
    // GET请求（参数拼接到url后面）
    NSString *requestUrl = self.url;
    if (self.params && [self.method isEqualToString:@"GET"]) {
        requestUrl = [self getURLQueryString:self.url params:self.params];
    }
    // 1.创建请求URL
    NSURL *requestURL = [NSURL URLWithString:requestUrl];
    // 2.创建一个网络请求
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL];
    request.HTTPMethod = self.method;
    // 3. 设置HTTP头
    if (self.headers) {
        [self.headers enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
            [request setValue:value forHTTPHeaderField:key];
        }];
    }
    // 4.设置请求体，编码参数（默认URL编码，可扩展为JSON）
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
    // 设置超时时间
    request.timeoutInterval = 20.0f;
    // 5.创建加载数据任务（处理网络请求，通过设置代理来接收数据）
    self.dataTask = [self.session dataTaskWithRequest:request];
    // 6.启动任务
    [self.dataTask resume];
}

/// 取消请求
- (void)cancelRequest {
    // 取消请求
    [self.dataTask cancel];
    self.dataTask = nil;
}

#pragma mark - Private Method
/// 请求结果（执行多次，回调流式数据）
- (void)onMessage:(NSString *)result {
    // 解析SSE数据，例如
    /**
     id:37
     event:result
     :HTTP_STATUS/200
     data:{"output":{"session_id":"","finish_reason":"stop","text":"我是你的智能助手。"},"request_id":"c70c58a4-89cd-97d2-b29f-3d4b6385390d"}
     */
    // 通过换行符分割输出内容，得到行数组
    NSArray *lines = [result componentsSeparatedByString:@"\n"];
    NSString *event = nil;
    id data = nil;
    // 遍历行数组
    for (NSString *line in lines) {
        if ([line hasPrefix:@"event:"]) {
            event = [[line substringFromIndex:6] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        } else if ([line hasPrefix:@"data:"]) {
            data = [[line substringFromIndex:5] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        } else if ([line isEqualToString:@""]) {
            // 空行（即分割后的最后一行）表示一个完整的 SSE 消息
            if (event && data && self.onMessageBlock) {
                NSData *jsonData = [data dataUsingEncoding:NSUTF8StringEncoding];
                NSError *jsonError = nil;
                NSDictionary *jsonDic = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&jsonError];
                if (jsonError) {
                    NSLog(@"JSON parsing error: %@", jsonError.localizedDescription);
                } else {
                    data = jsonDic;
                }
                self.onMessageBlock(event, data);
            }
            event = nil;
            data = nil;
        }
    }
}

/// 请求完成
- (void)onComplete {
    // 请求完成自动关闭
    [self cancelRequest];
    self.onCompleteBlock ? self.onCompleteBlock(): nil;
}

/// 请求失败
- (void)onError:(NSError *)error {
    [self cancelRequest];
    self.onErrorBlock ? self.onErrorBlock(error): nil;
}

#pragma mark - NSURLSessionDataDelegate methods
// 1.接受到服务器返回数据的时候调用，可能被调用多次
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"===收到SSE数据===\n%@", dataString);
    // 解析 SSE 数据格式
    [self onMessage:dataString];
}

// 2.请求完成或失败时调用
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error) {
        NSLog(@"请求失败：SSE connection failed with error: %@", error.localizedDescription);
        [self onError:error];
    } else {
        NSLog(@"请求完成：SSE connection completed");
        [self onComplete];
    }
}

// 获取GET请求带参数的请求url
- (NSString *)getURLQueryString:(NSString *)baseUrl params:(NSDictionary *)params {
    if (!params || params.count == 0) {
        return @"";
    }
    NSMutableArray *tempArr = [[NSMutableArray alloc] init];
    for (NSString *key in params) {
        NSString *value = [params[key] description]; // 不处理嵌套情况
        NSString *encodedKey = [key stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        NSString *encodedValue = [value stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        [tempArr addObject:[NSString stringWithFormat:@"%@=%@", encodedKey, encodedValue]];
    }
    NSString *queryString = [tempArr componentsJoinedByString:@"&"];
    // 构建完整的 url
    return [NSString stringWithFormat:@"%@?%@", baseUrl, queryString];
}

@end
