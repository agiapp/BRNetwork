//
//  BRBaseRequest.m
//  BRNetworkDemo
//
//  Created by 任波 on 2018/4/8.
//  Copyright © 2018年 91renb. All rights reserved.
//

#import "BRBaseRequest.h"
#import <YTKNetworkAgent.h>

// 私有定义,来自服务端定义
#define kBRCodeStatus           @"code"
#define kBRSuccess              @"success" // 头像上传成功时使用（此时没有code）
#define kBRMessage              @"msg"
#define kBRBody                 @"body"
#define kBRType                 @"type"

#define kBRXAuthFailedCode      @"X-Auth-Failed-Code"
#define kBRXAccessToken         @"X-Access-Token"
#define kBRXServiceId           @"X-Service-Id"
#define kBRBProductCode         @"B-Product-Code"

#define kBRXSignature           @"X-Signature"
#define kBRJsonRequest          @"*.jsonRequest"

// 令牌失效
NSString *const BRAccessTokenExpiredNotifKey = @"BRAccessTokenExpiredNotifKey";
// 被踢下线通知
NSString *const BRNotificationOfflineNotifKey = @"BRNotificationOfflineNotifKey";

@implementation BRBaseRequest

#pragma mark - 请求地址
- (NSString *)requestUrl {
    return kBRJsonRequest;
}

#pragma mark - 请求超时的时长
- (NSTimeInterval)requestTimeoutInterval {
    return 20;
}

#pragma mark - 请求方法
- (YTKRequestMethod)requestMethod {
    return YTKRequestMethodPOST;
}

#pragma mark - 请求序列化类型
- (YTKRequestSerializerType)requestSerializerType {
    return YTKRequestSerializerTypeJSON;
}

#pragma mark - 解析msg
- (NSString *)formatMessage:(BRRequestStatus)statusCode {
    NSDictionary *responseJSONObject = (NSDictionary *)self.responseJSONObject;
    return responseJSONObject[kBRMessage];
}

#pragma mark - 解析body，把服务器返回数据转换想要的数据
- (id)formatResponseObject:(id)responseObject {
    NSDictionary *data = responseObject;
    return data[@"body"];
}

- (NSDictionary *)requestHeaderFieldValueDictionary {
    return [self requestHeaderDictionary];
}

// HTTP头
- (NSDictionary *)requestHeaderDictionary {
    return nil;
}

#pragma mark - override Methods
- (void)startRequest:(BRRequestBlock)requestBlock {
    [self startWithCompletionBlockWithSuccess:^(__kindof YTKBaseRequest * _Nonnull request) {
        NSLog(@"请求成功！");
        [self printResponseData]; // 打印请求结果
        [self handleSuccess:requestBlock responseObject:request.responseJSONObject responseHeaders:request.responseHeaders];
    } failure:^(__kindof YTKBaseRequest * _Nonnull request) {
        NSLog(@"请求失败！");
        [self printResponseData]; // 打印请求结果
        [self handleFailure:requestBlock error:request.error responseHeaders:request.responseHeaders];
    }];
}

#pragma mark - private Method
- (void)handleSuccess:(BRRequestBlock)requestBlock
       responseObject:(id)responseObject
      responseHeaders:(NSDictionary *)responseHeaders {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            // message不可用时为@"", responseObject不可用时为nil
            BRRequestStatus status = [[responseObject objectForKey:kBRCodeStatus] integerValue];
            // 处理 response中 不是code, 是success的情况 (上传头像)
            if ([[responseObject allKeys] containsObject:kBRSuccess]) {
                if ([[responseObject objectForKey:kBRSuccess] integerValue] == 1) {
                    status = BRRequestStatusSuccess;
                } else {
                    status = BRRequestStatusFailure;
                }
            } else if (![[responseObject allKeys] containsObject:kBRCodeStatus]) {
                // 字典服务 既不返回code也不返回success时，默认是成功
                status = BRRequestStatusSuccess;
            }
            
            // 返回错误时, 需要解析message。服务器返回的错误没有用, 因为客户端需要显示中文。
            NSString *message = [self formatMessage:status];
            id object = [self formatResponseObject:responseObject];
            if (requestBlock) {
                requestBlock(status, message, object);
            }
        } else {
            if (requestBlock) {
                requestBlock(BRRequestStatusFailure, @"数据解析异常，请联系客服 T_T", nil);
            }
        }
    });
}

- (void)handleFailure:(BRRequestBlock)requestBlock error:(NSError *)error responseHeaders:(NSDictionary *)responseHeaders {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (requestBlock) {
            NSString *msg = @"服务器异常，请稍候再试!";
            switch (error.code) {
                case -1000:
                case -1002:
                    msg = @"系统异常，请稍后再试";
                    break;
                case -1001:
                    msg = @"请求超时，请检查您的网络!";
                    break;
                case -1005:
                case -1006:
                case -1009:
                    msg = @"网络异常，请检查您的网络!";
                    break;
                default:
                    break;
            }
            
            // 判断accessToken是否过期
            NSInteger authCode = [responseHeaders[kBRXAuthFailedCode] intValue];
            if (authCode == BRRequestStatusTokenFailure || authCode == BRRequestStatusLoginUserNotFound) {
                [[NSNotificationCenter defaultCenter] postNotificationName:BRAccessTokenExpiredNotifKey object:nil];
                msg = @"您的登录会话已失效，请重新登录";
            } else if (authCode == BRRequestStatusLoginFailure) {
                [[NSNotificationCenter defaultCenter] postNotificationName:BRNotificationOfflineNotifKey object:nil];
                msg = @"您的账号在其它地方登录，请检查密码是否被盗";
            } else if (authCode == BRRequestStatusEncryFailure) {
                msg = @"服务器异常，请稍候再试!";
            }
            requestBlock(BRRequestStatusFailure, msg, nil);
        }
    });
}

#pragma mark - 打印请求结果的详细信息
- (void)printResponseData {
    NSData *jsonData;
    if (self.responseJSONObject) {
        jsonData = [NSJSONSerialization dataWithJSONObject:self.responseJSONObject options:NSJSONWritingPrettyPrinted error:nil];
    }
    NSString *jsonString;
    if (jsonData) {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    } else {
        jsonString = self.responseString;
    }
    NSLog(@"%@\n%@\n%@\n%@\n%@\n********* Code=%@ *************", [[YTKNetworkAgent sharedAgent] buildRequestUrl:self], self.requestHeaderFieldValueDictionary, self.requestArgument, self.responseHeaders, jsonString, @(self.response.statusCode));
}

@end
