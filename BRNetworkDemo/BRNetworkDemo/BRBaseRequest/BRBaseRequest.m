//
//  BRBaseRequest.m
//  BRNetworkDemo
//
//  Created by renbo on 2018/4/8.
//  Copyright © 2018年 irenb. All rights reserved.
//

#import "BRBaseRequest.h"
#import <AFNetworking/AFNetworking.h>

// 接口基本地址
NSString *const kApiUrl = @"https://api.xxxx.com/app";


@interface BRBaseRequest ()

@end

@implementation BRBaseRequest

// 懒调用：这个方法会在 第一次初始化这个类之前 被调用，我们用它来初始化静态变量。
+ (void)initialize {
    // 只执行一次
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [BRNetwork setRequestSerializerType:BRRequestSerializerJSON];
        // 响应序列化类型是HTTP时，请求结果输出的是二进制数据
        [BRNetwork setResponseSerializerType:BRResponseSerializerHTTP];
    });
}

#pragma mark - 设置接口基本Url
- (NSString *)requestUrl {
    return kApiUrl;
}

#pragma mark - 设置请求头
- (NSDictionary *)requestHeaderDictionaryWithParams:(id)params method:(BRRequestMethod)method {
    NSMutableDictionary *headerDic = [[NSMutableDictionary alloc]init];
    [headerDic setObject:@"Bearer sk-xxxxxx" forKey:@"Authorization"];
    [headerDic setObject:@"enable" forKey:@"X-DashScope-SSE"];
    [headerDic setObject:@"application/json" forKey:@"Content-Type"];
    
    return headerDic;
}

#pragma mark - get 方法
- (void)getWithUrl:(NSString *)url
            params:(NSDictionary *)params
           success:(BRRequestSuccess)successBlock
           failure:(BRRequestFailure)failureBlock {
    if (!(url && [url hasPrefix:@"http"])) {
        [BRNetwork setBaseUrl:[self requestUrl]];
    }
    // 1.设置请求头
    NSDictionary *header = [self requestHeaderDictionaryWithParams:params method:BRRequestMethodGET];
    // 2.请求方法
    [BRNetwork requestWithMethod:BRRequestMethodGET url:url params:params headers:header success:^(NSURLSessionDataTask * _Nullable task, id  _Nullable responseObject) {
        if (task) {
            NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
            // 获取响应头：NSDictionary *headFilesDic = response.allHeaderFields;
            self.responseBlock ? self.responseBlock(response): nil;
        }
        [self handlerRequestSuccess:successBlock path:url params:params headers:header responseObject:responseObject];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handlerRequestFailure:failureBlock path:url params:params headers:header error:error];
    }];
}

#pragma mark - post 方法
- (void)postWithUrl:(NSString *)url
             params:(NSDictionary *)params
            success:(BRRequestSuccess)successBlock
            failure:(BRRequestFailure)failureBlock {
    if (!(url && [url hasPrefix:@"http"])) {
        [BRNetwork setBaseUrl:[self requestUrl]];
    }
    // 1.设置请求头
    NSDictionary *header = [self requestHeaderDictionaryWithParams:params method:BRRequestMethodPOST];
    // 2.请求方法
    [BRNetwork requestWithMethod:BRRequestMethodPOST url:url params:params headers:header success:^(NSURLSessionDataTask * _Nullable task, id  _Nullable responseObject) {
        if (task) {
            NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
            // 获取响应头：NSDictionary *headFilesDic = response.allHeaderFields;
            self.responseBlock ? self.responseBlock(response): nil;
        }
        [self handlerRequestSuccess:successBlock path:url params:params headers:header responseObject:responseObject];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handlerRequestFailure:failureBlock path:url params:params headers:header error:error];
    }];
}

#pragma mark - 请求成功的处理
- (void)handlerRequestSuccess:(BRRequestSuccess)successBlock
                         path:(NSString *)path
                       params:(NSDictionary *)params
                      headers:(NSDictionary *)header
               responseObject:(NSDictionary *)responseObject {
    if (responseObject && [NSJSONSerialization isValidJSONObject:responseObject]) {
        NSInteger requestStatus = [responseObject[@"Code"] integerValue];
        NSString *message = responseObject[@"Msg"];
        id result = responseObject[@"Result"];
        
        [self handlerMessageWithRequestStatus:requestStatus message:message];
        successBlock ? successBlock(requestStatus, message, result) : nil;
    }
#ifdef DEBUG
    NSString *url = [path hasPrefix:@"http"] ? path: [NSString stringWithFormat:@"%@%@", [self requestUrl], path];
    NSLog(@"\nurl：%@\nheader：\n%@\nparams：\n%@\nresponse：\n%@\n\n", url, header, params, responseObject);
#endif
}

#pragma mark - 请求失败的处理
- (void)handlerRequestFailure:(BRRequestFailure)failureBlock
                         path:(NSString *)path
                       params:(NSDictionary *)params
                      headers:(NSDictionary *)header
                        error:(NSError *)error {
#ifdef DEBUG
    NSString *url = [path hasPrefix:@"http"] ? path: [NSString stringWithFormat:@"%@%@", [self requestUrl], path];
    NSLog(@"\nurl：%@\nheader：\n%@\nparams：\n%@\nresponse：\n%@\n\n", url, header, params, error);
#endif
    // 常见错误类型：
    // error=Error Domain=com.alamofire.error.serialization.response Code=-1011 "Request failed: unauthorized (401)"
    // error=Error Domain=com.alamofire.error.serialization.response Code=-1011 "Request failed: not found (404)"
    // error=Error Domain=com.alamofire.error.serialization.response Code=-1011 "Request failed: internal server error (500)"
    // error=Error Domain=NSURLErrorDomain Code=-1001 "The request timed out."
    // error=Error Domain=NSURLErrorDomain Code=-1009 "The Internet connection appears to be offline."
    // error=Error Domain=NSURLErrorDomain Code=-1202 "The certificate for this server is invalid. You might be connecting to a server that is pretending to be “manager.zhong360.net” which could put your confidential information at risk."
    // error=Error Domain=NSURLErrorDomain Code=-1003 "未能找到使用指定主机名的服务器。"
    // error=Error Domain=NSURLErrorDomain Code=-1200 "发生了 SSL 错误，无法建立与该服务器的安全连接。"
    NSInteger statusCode = error.code;
    NSString *message = error.localizedDescription;
    if (error.code == NSURLErrorBadServerResponse) { // Code=-1011
        if (error.userInfo) {
            NSHTTPURLResponse *response = error.userInfo[AFNetworkingOperationFailingURLResponseErrorKey];
            if (response) {
                statusCode = response.statusCode;
                //NSLog(@"【请求失败1】服务器返回结果：%@", response);
            }
            
            NSData *error_data = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
            if (error_data) {
                //NSLog(@"【请求失败2】服务器返回的错误提示信息：%@", [[NSString alloc]initWithData:error_data encoding:NSUTF8StringEncoding]);
            }
        }
    }
    
    [self handlerMessageWithRequestStatus:statusCode message:message];
    failureBlock ? failureBlock(statusCode, message, error) : nil;
}

#pragma mark - 全局处理状态码提示
- (void)handlerMessageWithRequestStatus:(NSInteger)requestStatus message:(NSString *)message {
    switch (requestStatus) {
        case BRRequestStatusSuccess:    // 200
        {
            NSLog(@"请求成功");
        }
            break;
        case BRRequestStatusNotFound:   // 404
        {
            NSLog(@"找不到资源");
        }
            break;
        case NSURLErrorTimedOut: // -1001
        {
            NSLog(@"网络不给力");
        }
            break;
        case NSURLErrorCannotFindHost:          // -1003：未能找到使用指定主机名的服务器。
        case NSURLErrorSecureConnectionFailed:  // -1200：发生了SSL错误，无法建立与该服务器的安全连接
        {
            NSLog(@"当前网络访问异常");
        }
            break;
        case NSURLErrorNotConnectedToInternet: // -1009
        {
            NSLog(@"网络连接异常，请检查网络设置");
        }
            break;
        case BRRequestStatusSignError: // 400
        {
            NSLog(@"数据签名失败");
        }
            break;
        case BRRequestStatusUnauthorized: // 401
        {
            NSLog(@"登录失效，请重新登录");
        }
            break;
        case BRRequestStatusServerException: // 500
        case NSURLErrorUnknown: // -1
        {
            NSLog(@"服务器异常");
        }
            break;
        case BRRequestStatusServerUnavailable: // 503
        {
            NSLog(@"系统正在维护中，请稍后再试（503）");
        }
            break;
            
        default:
            break;
    }
}

@end
