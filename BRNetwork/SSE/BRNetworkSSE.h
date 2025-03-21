//
//  BRNetworkSSE.h
//  BRNetworkDemo
//
//  Created by renbo on 2025/3/21.
//  Copyright © 2018年 irenb. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^BROnMessageBlock)(NSString * _Nullable event, id _Nullable data);
typedef void(^BROnCompleteBlock)(void);
typedef void(^BROnErrorBlock)(NSError * _Nonnull error);

NS_ASSUME_NONNULL_BEGIN

@interface BRNetworkSSE : NSObject
/** 请求地址 */
@property (nonatomic, copy) NSString *url;
/** 请求方法 */
@property (nonatomic, copy) NSString *method;
/** 请求头 */
@property (nullable, nonatomic, copy) NSDictionary *headers;
/** 请求参数（一般为字典类型）*/
@property (nullable, nonatomic, strong) id params;
/** 请求结果的回调（执行多次，回调流式数据） */
@property (nullable, nonatomic, copy) BROnMessageBlock onMessageBlock;
/** 请求完成的回调 */
@property (nullable, nonatomic, copy) BROnCompleteBlock onCompleteBlock;
/** 请求失败的回调 */
@property (nullable, nonatomic, copy) BROnErrorBlock onErrorBlock;

/** 开始请求 */
- (void)startRequest;
/** 取消请求 */
- (void)cancelRequest;

/**
 *  GET请求方法
 *
 *  @param url 请求地址
 *  @param params 请求参数
 *  @param headers 请求头
 *  @param onMessageBlock 请求成功的回调
 *  @param onErrorBlock 请求失败的回调
 */
+ (void)getWithUrl:(NSString *)url
            params:(nullable NSDictionary *)params
           headers:(nullable NSDictionary *)headers
    onMessageBlock:(nullable BROnMessageBlock)onMessageBlock
      onErrorBlock:(nullable BROnErrorBlock)onErrorBlock;

/**
 *  POST请求方法
 *
 *  @param url 请求地址
 *  @param params 请求参数
 *  @param headers 请求头
 *  @param onMessageBlock 请求成功的回调
 *  @param onErrorBlock 请求失败的回调
 */
+ (void)postWithUrl:(NSString *)url
             params:(nullable NSDictionary *)params
            headers:(nullable NSDictionary *)headers
     onMessageBlock:(nullable BROnMessageBlock)onMessageBlock
       onErrorBlock:(nullable BROnErrorBlock)onErrorBlock;

@end

NS_ASSUME_NONNULL_END
