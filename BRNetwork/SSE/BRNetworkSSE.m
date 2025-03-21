//
//  BRNetworkSSE.m
//  BRNetworkDemo
//
//  Created by renbo on 2018/4/27.
//  Copyright © 2018年 irenb. All rights reserved.
//

#import "BRNetworkSSE.h"

@interface BRFetchEventSource ()<NSURLSessionDataDelegate>
// 会话对象
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLSessionDataTask *dataTask;

@end

@implementation BRFetchEventSource

- (instancetype)init {
    if (self = [super init]) {
        // 默认会话模式
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        // 通过设置配置、代理、队列来创建会话对象
        self.session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return self;
}

- (void)startListening {
    // 1.创建请求URL
    NSURL *requestURL = [NSURL URLWithString:self.url];
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
    if (self.body && [self.method isEqualToString:@"POST"]) {
        NSError *jsonError = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self.body options:0 error:&jsonError];
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

- (void)stopListening {
    // 取消请求
    [self.dataTask cancel];
    self.dataTask = nil;
}

#pragma mark - NSURLSessionDataDelegate methods
// 接受到服务器返回数据的时候调用，可能被调用多次
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"===收到SSE数据===\n%@", dataString);
    
    // 解析 SSE 数据格式
    [self onMessage:dataString];
}

// 请求完成或失败时调用
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error) {
        NSLog(@"请求失败：SSE connection failed with error: %@", error.localizedDescription);
    } else {
        NSLog(@"请求完成：SSE connection completed");
    }
    [self stopListening];
}

@end

@implementation BRNetworkSSE

+ (void)getWithUrl:(NSString *)url
            params:(nullable NSDictionary *)params
           headers:(nullable NSDictionary *)headers
    onMessageBlock:(BROnMessageBlock)onMessageBlock
      onErrorBlock:(BROnErrorBlock)onErrorBlock {
    BRFetchEventSource *eventSource = [[BRFetchEventSource alloc] init];
    eventSource.url = [self getFullUrl:url params:params];
    eventSource.method = @"GET";
    eventSource.headers = headers;
    eventSource.onMessageBlock = onMessageBlock;
    [eventSource startListening];
}

+ (void)postWithUrl:(NSString *)url
             params:(nullable NSDictionary *)params
            headers:(nullable NSDictionary *)headers
     onMessageBlock:(BROnMessageBlock)onMessageBlock
       onErrorBlock:(BROnErrorBlock)onErrorBlock {
    BRFetchEventSource *eventSource = [[BRFetchEventSource alloc] init];
    eventSource.url = url;
    eventSource.method = @"POST";
    eventSource.body = params;
    eventSource.headers = headers;
    eventSource.onMessageBlock = onMessageBlock;
    [eventSource startListening];
}

// 获取GET请求带参数的请求url
+ (NSString *)getFullUrl:(NSString *)baseUrl params:(NSDictionary *)params {
    if (!params || params.count == 0) {
        return @"";
    }
    
    NSMutableArray *tempArr = [NSMutableArray array];
    for (NSString *key in params) {
        NSString *value = [params[key] description];
        NSString *encodedKey = [key stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        NSString *encodedValue = [value stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        [tempArr addObject:[NSString stringWithFormat:@"%@=%@", encodedKey, encodedValue]];
    }
    NSString *queryString = [tempArr componentsJoinedByString:@"&"];
    // 构建完整的 url
    NSString *fullUrl = [NSString stringWithFormat:@"%@?%@", baseUrl, queryString];

    return fullUrl;
}

@end
