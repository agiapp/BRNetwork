//
//  BRCacheNetwork.h
//  BRNetworkDemo
//
//  Created by renbo on 2018/4/27.
//  Copyright © 2018年 irenb. All rights reserved.
//

#import "BRNetwork.h"

/** 缓存方式 */
typedef NS_ENUM(NSUInteger, BRCachePolicy) {
    /** 仅从网络获取数据 */
    BRCachePolicyNetworkOnly = 0,
    /** 先从网络获取数据，再更新本地缓存 */
    BRCachePolicyNetworkAndSaveCache,
    /** 先从网络获取数据，再更新本地缓存，如果网络获取失败还会从缓存获取 */
    BRCachePolicyNetworkElseCache,
    /** 仅从缓存获取数据 */
    BRCachePolicyCacheOnly,
    /** 先从缓存获取数据，如果没有再获取网络数据，网络数据获取成功后更新本地缓存 */
    BRCachePolicyCacheElseNetwork,
    /** 先从缓存获取数据，同时再获取网络数据并更新本地缓存，如果本地不存在缓存就返回网络获取的数据 */
    BRCachePolicyCacheAndNetwork,
    /** 先从缓存读取数据，然后在从网络获取并且缓存，在这种情况下，Block将产生两次调用 */
    BRCachePolicyCacheThenNetwork
};

NS_ASSUME_NONNULL_BEGIN

@interface BRCacheNetwork : BRNetwork
/**
 *  GET请求方法
 *
 *  @param url 请求地址
 *  @param params 请求参数
 *  @param headers 请求头
 *  @param cachePolicy 缓存策略
 *  @param successBlock 请求成功的回调
 *  @param failureBlock 请求失败的回调
 */
+ (void)getWithUrl:(NSString *)url
            params:(nullable id)params
           headers:(nullable NSDictionary *)headers
       cachePolicy:(BRCachePolicy)cachePolicy
           success:(nullable BRHttpSuccessBlock)successBlock
           failure:(nullable BRHttpFailureBlock)failureBlock;

/**
 *  POST请求方法
 *
 *  @param url 请求地址
 *  @param params 请求参数
 *  @param headers 请求头
 *  @param cachePolicy 缓存策略
 *  @param successBlock 请求成功的回调
 *  @param failureBlock 请求失败的回调
 */
+ (void)postWithUrl:(NSString *)url
            params:(nullable id)params
           headers:(nullable NSDictionary *)headers
       cachePolicy:(BRCachePolicy)cachePolicy
           success:(nullable BRHttpSuccessBlock)successBlock
           failure:(nullable BRHttpFailureBlock)failureBlock;

/**
 *  网络请求方法
 *
 *  @param method 请求方法
 *  @param url 请求地址
 *  @param params 请求参数
 *  @param headers 请求头
 *  @param cachePolicy 缓存策略
 *  @param successBlock 请求成功的回调
 *  @param failureBlock 请求失败的回调
 */
+ (void)requestWithMethod:(BRRequestMethod)method
                      url:(NSString *)url
                   params:(nullable id)params
                  headers:(nullable NSDictionary *)headers
              cachePolicy:(BRCachePolicy)cachePolicy
                  success:(nullable BRHttpSuccessBlock)successBlock
                  failure:(nullable BRHttpFailureBlock)failureBlock;
@end

NS_ASSUME_NONNULL_END
