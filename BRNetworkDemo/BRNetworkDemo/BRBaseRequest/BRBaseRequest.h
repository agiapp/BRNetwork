//
//  BRBaseRequest.h
//  BRNetworkDemo
//
//  Created by renbo on 2018/4/8.
//  Copyright © 2018年 irenb. All rights reserved.
//
//  二次封装 BRNetwork 库
//

#import <Foundation/Foundation.h>
#import <BRNetwork/BRNetwork.h>

/** 状态码：来自服务器定义 */
typedef NS_ENUM(NSInteger , BRRequestStatus) {
    /** 200:请求成功 */
    BRRequestStatusSuccess = 200,
    /** 300:警告 */
    BRRequestStatusWarning = 300,
    /** 400:错误请求/参数异常（签名失败） */
    BRRequestStatusSignError = 400,
    /** 401:未授权（登录过期/账号被踢下线） */
    BRRequestStatusUnauthorized = 401,
    /** 404:找不到资源 */
    BRRequestStatusNotFound = 404,
    /** 500:服务器异常 */
    BRRequestStatusServerException = 500,
    /** 503:服务不可用 */
    BRRequestStatusServerUnavailable = 503
};

/** 成功的回调 */
typedef void (^BRRequestSuccess)(BRRequestStatus requestStatus, NSString *message, id result);
/** 失败的回调 */
typedef void (^BRRequestFailure)(BRRequestStatus requestStatus, NSString *message, NSError *error);

/** 获取响应体的回调 */
typedef void (^BRHTTPURLResponseBlock)(NSHTTPURLResponse *response);

/** 请求完成后的回调 */
typedef void (^BRCompletionHandler)(BRRequestStatus requestStatus, id value);

@interface BRBaseRequest : NSObject

/** 缓存策略 */
//@property (nonatomic, assign) BRCachePolicy cachePolicy;

/** 获取响应体的回调 */
@property (nonatomic, copy) BRHTTPURLResponseBlock responseBlock;

/**
 *  get方法
 *
 *  @param url 请求地址
 *  @param params 请求参数
 *  @param successBlock 请求成功的回调
 *  @param failureBlock 请求失败的回调
 */
- (void)getWithUrl:(NSString *)url
            params:(NSDictionary *)params
           success:(BRRequestSuccess)successBlock
           failure:(BRRequestFailure)failureBlock;

/**
 *  post方法
 *
 *  @param url 请求地址
 *  @param params 请求参数
 *  @param successBlock 请求成功的回调
 *  @param failureBlock 请求失败的回调
 */
- (void)postWithUrl:(NSString *)url
             params:(NSDictionary *)params
            success:(BRRequestSuccess)successBlock
            failure:(BRRequestFailure)failureBlock;

@end
