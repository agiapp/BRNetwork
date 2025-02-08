//
//  BRCacheNetwork.m
//  BRNetworkDemo
//
//  Created by renbo on 2018/4/27.
//  Copyright © 2018年 irenb. All rights reserved.
//

#import "BRCacheNetwork.h"
#import "BRCache.h"

@implementation BRCacheNetwork
#pragma mark - GET请求方法
+ (void)getWithUrl:(NSString *)url
            params:(nullable id)params
           headers:(nullable NSDictionary *)headers
       cachePolicy:(BRCachePolicy)cachePolicy
           success:(nullable BRHttpSuccessBlock)successBlock
           failure:(nullable BRHttpFailureBlock)failureBlock {
    [self requestWithMethod:BRRequestMethodGET url:url params:params headers:headers cachePolicy:cachePolicy success:successBlock failure:failureBlock];
}

#pragma mark - POST请求方法
+ (void)postWithUrl:(NSString *)url
             params:(nullable id)params
            headers:(nullable NSDictionary *)headers
        cachePolicy:(BRCachePolicy)cachePolicy
            success:(nullable BRHttpSuccessBlock)successBlock
            failure:(nullable BRHttpFailureBlock)failureBlock {
    [self requestWithMethod:BRRequestMethodPOST url:url params:params headers:headers cachePolicy:cachePolicy success:successBlock failure:failureBlock];
}

#pragma mark - 网络请求公共方法
+ (void)requestWithMethod:(BRRequestMethod)method
                      url:(NSString *)url
                   params:(nullable id)params
                  headers:(nullable NSDictionary *)headers
              cachePolicy:(BRCachePolicy)cachePolicy
                  success:(nullable BRHttpSuccessBlock)successBlock
                  failure:(nullable BRHttpFailureBlock)failureBlock {
    if (cachePolicy == BRCachePolicyNetworkOnly) {
        [self requestWithMethod:method url:url params:params headers:headers success:successBlock failure:failureBlock];
    } else if (cachePolicy == BRCachePolicyNetworkAndSaveCache) {
        [self requestWithMethod:method url:url params:params headers:headers success:^(NSURLSessionDataTask *task, id responseObject) {
            // 更新缓存
            [BRCache saveHttpCache:responseObject url:url params:params];
            successBlock ? successBlock(task, responseObject) : nil;
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            failureBlock ? failureBlock(task, error) : nil;
        }];
    } else if (cachePolicy == BRCachePolicyNetworkElseCache) {
        [self requestWithMethod:method url:url params:params headers:headers success:^(NSURLSessionDataTask *task, id responseObject) {
            // 更新缓存
            [BRCache saveHttpCache:responseObject url:url params:params];
            successBlock ? successBlock(task, responseObject) : nil;
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            [self getHttpCache:url params:params headers:headers resultBlock:^(id<NSCoding> object) {
                if (object) {
                    successBlock ? successBlock(task, object) : nil;
                } else {
                    failureBlock ? failureBlock(task, error) : nil;
                }
            }];
        }];
    } else if (cachePolicy == BRCachePolicyCacheOnly) {
        [self getHttpCache:url params:params headers:headers resultBlock:^(id<NSCoding> object) {
            successBlock ? successBlock(nil, object) : nil;
        }];
    } else if (cachePolicy == BRCachePolicyCacheElseNetwork) {
        // 先从缓存读取数据
        [self getHttpCache:url params:params headers:headers resultBlock:^(id<NSCoding> object) {
            if (object) {
                successBlock ? successBlock(nil, object) : nil;
            } else {
                // 如果没有缓存再从网络获取
                [self requestWithMethod:method url:url params:params headers:headers success:^(NSURLSessionDataTask *task, id responseObject) {
                    // 更新缓存
                    [BRCache saveHttpCache:responseObject url:url params:params];
                    successBlock ? successBlock(task, responseObject) : nil;
                } failure:^(NSURLSessionDataTask *task, NSError *error) {
                    failureBlock ? failureBlock(task, error) : nil;
                }];
            }
        }];
    } else if (cachePolicy == BRCachePolicyCacheAndNetwork) {
        // 先从缓存读取数据
        [self getHttpCache:url params:params headers:headers resultBlock:^(id<NSCoding> object) {
            if (object) {
                successBlock ? successBlock(nil, object) : nil;
            }
            // 同时再从网络获取
            [self requestWithMethod:method url:url params:params headers:headers success:^(NSURLSessionDataTask *task, id responseObject) {
                // 更新本地缓存
                [BRCache saveHttpCache:responseObject url:url params:params];
                // 如果本地不存在缓存，就获取网络数据
                if (!object) {
                    successBlock ? successBlock(task, responseObject) : nil;
                }
            } failure:^(NSURLSessionDataTask *task, NSError *error) {
                failureBlock ? failureBlock(task, error) : nil;
            }];
        }];
    } else if (cachePolicy == BRCachePolicyCacheThenNetwork) {
        // 先从缓存读取数据（这种情况successBlock调用两次）
        [self getHttpCache:url params:params headers:headers resultBlock:^(id<NSCoding> object) {
            if (object) {
                successBlock ? successBlock(nil, object) : nil;
            }
            // 再从网络获取
            [self requestWithMethod:method url:url params:params headers:headers success:^(NSURLSessionDataTask *task, id responseObject) {
                // 更新缓存
                [BRCache saveHttpCache:responseObject url:url params:params];
                successBlock ? successBlock(task, responseObject) : nil;
            } failure:^(NSURLSessionDataTask *task, NSError *error) {
                failureBlock ? failureBlock(task, error) : nil;
            }];
        }];
    } else {
        // 未知缓存策略 (使用BRCachePolicyNetworkOnly)
        [self requestWithMethod:method url:url params:params headers:headers success:successBlock failure:failureBlock];
    }
}

#pragma mark - 异步 获取缓存的数据
+ (void)getHttpCache:(NSString *)url params:(nullable NSDictionary *)params headers:(nullable NSDictionary *)headers resultBlock:(nullable void (^)(id<NSCoding> object))resultBlock {
    [BRCache getHttpCache:url params:params block:^(id<NSCoding> object) {
        // if (_isOpenLog) BRApiLog(@"\nurl：%@\nheader：\n%@\nparams：\n%@\ncache：\n%@\n\n", url, headers, params, object);
        resultBlock(object);
    }];
}

@end
