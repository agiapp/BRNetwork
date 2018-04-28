//
//  BRCache.h
//  BRNetworkDemo
//
//  Created by 任波 on 2018/4/8.
//  Copyright © 2018年 91renb. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BRCache : NSObject
/**
 *  缓存网络数据
 *
 *  @param responseObj  服务器返回的数据
 *  @param url          请求路径
 *  @param params       请求参数
 *
 *  这里是根据(url + params)拼接缓存数据对应的key值
 */

+ (void)saveHttpCache:(id)responseObj url:(NSString *)url params:(NSDictionary *)params;

/**
 *  同步 获取缓存的数据(根据存入时候填入的key值来取出对应的数据)
 *
 *  @param url      请求路径
 *  @param params   请求参数
 *
 *  @return 缓存的数据
 */

+ (id)getHttpCache:(NSString *)url params:(NSDictionary *)params;

/**
 *  异步 获取缓存的数据(根据存入时候填入的key值来取出对应的数据)
 *
 *  @param url      请求路径
 *  @param params   请求参数
 *  @param block    异步回调缓存的数据
 *
 */

+ (void)getHttpCache:(NSString *)url params:(NSDictionary *)params block:(void(^)(id<NSCoding> object))block;

/** 获取网络缓存的总大小 bytes(字节) */
+ (NSInteger)getAllHttpCacheSize;

/** 删除所有网络缓存 */
+ (void)removeAllHttpCache;

/** 过滤缓存Key */
+ (void)setFiltrationCacheKey:(NSArray *)filtrationCacheKey;

@end
