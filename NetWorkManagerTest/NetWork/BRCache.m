//
//  BRCache.m
//  AiBaoYun
//
//  Created by 任波 on 17/4/10.
//  Copyright © 2017年 aby. All rights reserved.
//

#import "BRCache.h"
#import <YYCache.h>
#import <YYDiskCache.h>

static YYCache *_dataCache;
static NSString *const httpCache = @"HttpCache";

@implementation BRCache

+ (void)initialize {
    _dataCache = [YYCache cacheWithName:httpCache];
}

#pragma mark - 缓存网络数据
+ (void)saveHttpCache:(id)responseObj url:(NSString *)url params:(NSDictionary *)params {
    NSString *cacheKey = [self getCacheKey:url params:params];
    // 异步缓存,不会阻塞主线程
    [_dataCache setObject:responseObj forKey:cacheKey withBlock:nil];
}

#pragma mark - 同步 获取缓存的数据
+ (id)getHttpCache:(NSString *)url params:(NSDictionary *)params {
    NSString *cacheKey = [self getCacheKey:url params:params];
    // 根据存入时候填入的key值来取出对应的数据
    return [_dataCache objectForKey:cacheKey];
}

#pragma mark - 异步 获取缓存的数据
+ (void)getHttpCache:(NSString *)url params:(NSDictionary *)params block:(void(^)(id<NSCoding> object))block {
    NSString *cacheKey = [self getCacheKey:url params:params];
    [_dataCache objectForKey:cacheKey withBlock:^(NSString * _Nonnull key, id<NSCoding>  _Nonnull object) {
        dispatch_async(dispatch_get_main_queue(), ^{
            block(object);
        });
    }];
}

#pragma mark - 获取网络缓存的总大小
+ (NSInteger)getAllHttpCacheSize {
    return [_dataCache.diskCache totalCost];
}

#pragma mark - 删除所有网络缓存
+ (void)removeAllHttpCache {
    [_dataCache.diskCache removeAllObjects];
}

/** 获取缓存数据对应的key值 */
+ (NSString *)getCacheKey:(NSString *)url params:(NSDictionary *)params {
    if (params == nil) {
        return url;
    }
    // 将参数字典转换成字符串
    NSData *data = [NSJSONSerialization dataWithJSONObject:params options:0 error:nil];
    NSString *paramsStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    // 将url与转换好的参数字符串拼接在一起，成为最终存储的key值
    NSString *keyStr = [NSString stringWithFormat:@"%@%@", url, paramsStr];
    return keyStr;
}


@end
