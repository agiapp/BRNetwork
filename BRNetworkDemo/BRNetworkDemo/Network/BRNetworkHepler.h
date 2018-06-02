//
//  BRNetworkHepler.h
//  BRNetworkDemo
//
//  Created by 任波 on 2018/4/28.
//  Copyright © 2018年 91renb. All rights reserved.
//
//  二次封装 BRNetwork 库
//

#import <Foundation/Foundation.h>

/** 成功的回调 */
typedef void (^BRRequestSuccess)(id responseObject, NSString *message);
/** 失败的回调 */
typedef void (^BRRequestFailure)(NSError *error, NSString *message);

@interface BRNetworkHepler : NSObject

/**
 *  get方法
 *
 *  @param url 请求地址
 *  @param params 请求参数
 *  @param successBlock 请求成功的回调
 *  @param failureBlock 请求失败的回调
 */
+ (void)getWithUrl:(NSString *)url
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
+ (void)postWithUrl:(NSString *)url
             params:(NSDictionary *)params
            success:(BRRequestSuccess)successBlock
            failure:(BRRequestFailure)failureBlock;

@end
