//
//  BRNetwork.h
//  BRNetworkDemo
//
//  Created by 任波 on 2018/4/27.
//  Copyright © 2018年 91renb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/** 请求方法 */
typedef NS_ENUM(NSUInteger, BRRequestMethod) {
    /** GET请求方法 */
    BRRequestMethodGET = 0,
    /** POST请求方法 */
    BRRequestMethodPOST,
    /** HEAD请求方法 */
    BRRequestMethodHEAD,
    /** PUT请求方法 */
    BRRequestMethodPUT,
    /** PATCH请求方法 */
    BRRequestMethodPATCH,
    /** DELETE请求方法 */
    BRRequestMethodDELETE
};

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

/** 网络状态 */
typedef NS_ENUM(NSUInteger, BRNetworkStatus) {
    /** 未知网络 */
    BRNetworkStatusUnknown,
    /** 无网络 */
    BRNetworkStatusNotReachable,
    /** 手机网络 */
    BRNetworkStatusReachableViaWWAN,
    /** WIFI网络 */
    BRNetworkStatusReachableViaWiFi
};

/** 请求序列化类型 */
typedef NS_ENUM(NSUInteger, BRRequestSerializer) {
    /** 设置请求数据为JSON格式 */
    BRRequestSerializerJSON,
    /** 设置请求数据为二进制格式 */
    BRRequestSerializerHTTP
};

/** 响应序列化类型 */
typedef NS_ENUM(NSUInteger, BRResponseSerializer) {
    /** 设置响应数据为JSON格式 */
    BRResponsetSerializerJSON,
    /** 设置响应数据为二进制格式 */
    BRResponseSerializerHTTP
};

/** 成功的回调 */
typedef void (^BRHttpSuccessBlock)(id _Nullable responseObject);
/** 失败的回调 */
typedef void (^BRHttpFailureBlock)(NSError *error);
/** 网络状态Block */
typedef void(^BRNetworkStatusBlock)(BRNetworkStatus status);


NS_ASSUME_NONNULL_BEGIN

@interface BRNetwork : NSObject

/** 设置接口根路径 */
+ (void)setBaseUrl:(nullable NSString *)baseUrl;

/** 设置接口基本参数/公共参数(如:用户ID, Token) */
+ (void)setBaseParameters:(nullable NSDictionary *)params;

/** 加密接口参数/加密Body */
+ (void)setEncodeParameters:(nullable NSDictionary *)params;

/** 是否开启日志打印 */
+ (void)setIsOpenLog:(BOOL)isOpenLog;

/** 是否需要加密传输 */
+ (void)setIsNeedEncry:(BOOL)isNeedEncry;

/** 设置请求超时时间(默认30s) */
+ (void)setRequestTimeoutInterval:(NSTimeInterval)timeout;

/** 请求序列化类型 */
+ (void)setRequestSerializerType:(BRRequestSerializer)type;

/** 响应序列化类型 */
+ (void)setResponseSerializerType:(BRResponseSerializer)type;

/**
 *  设置自建证书的Https请求
 *
 *  @param cerPath 自建https证书路径
 *  @param validatesDomainName 是否验证域名(默认YES) 如果证书的域名与请求的域名不一致，需设置为NO
 */
+ (void)setSecurityPolicyWithCerPath:(NSString *)cerPath validatesDomainName:(BOOL)validatesDomainName;

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
            params:(nullable NSDictionary *)params
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
            params:(nullable NSDictionary *)params
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
                   params:(nullable NSDictionary *)params
                  headers:(nullable NSDictionary *)headers
              cachePolicy:(BRCachePolicy)cachePolicy
                  success:(nullable BRHttpSuccessBlock)successBlock
                  failure:(nullable BRHttpFailureBlock)failureBlock;

/**
 *  下载文件
 *
 *  @param url              请求地址
 *  @param progress         下载进度的回调
 *  @param success          下载成功的回调
 *  @param failure          下载失败的回调
 *
 */

+ (void)downloadFileWithUrl:(NSString *)url
                   progress:(nullable void(^)(NSProgress *progress))progress
                    success:(nullable void(^)(NSString *filePath))success
                    failure:(nullable void(^)(NSError *error))failure;


/**
 *  上传文件
 *
 *  @param Url              请求地址
 *  @param params           请求参数
 *  @param nameKey          文件对应服务器上的字段
 *  @param filePath         文件本地的沙盒路径
 *  @param progress         上传进度的回调
 *  @param success          请求成功的回调
 *  @param failure          请求失败的回调
 *
 */
+ (void)uploadFileWithUrl:(NSString *)Url
                   params:(nullable id)params
                  nameKey:(nullable NSString *)nameKey
                 filePath:(nullable NSString *)filePath
                 progress:(nullable void(^)(NSProgress *progress))progress
                  success:(nullable void(^)(id responseObject))success
                  failure:(nullable void(^)(NSError *error))failure;

/**
 *  上传单/多张图片
 *
 *  @param Url              请求地址
 *  @param params           请求参数
 *  @param nameKey          图片对应服务器上的字段
 *  @param images           图片数组
 *  @param fileNames        图片文件名数组, 可以为nil, 数组内的文件名默认为当前日期时间"yyyyMMddHHmmss"
 *  @param imageScale       图片文件压缩比 范围 (0.0f ~ 1.0f)
 *  @param imageType        图片文件的类型,例:png、jpg(默认类型)....
 *  @param progress         上传进度的回调
 *  @param success          请求成功的回调
 *  @param failure          请求失败的回调
 *
 */
+ (void)uploadImagesWithUrl:(NSString *)Url
                     params:(nullable id)params
                    nameKey:(nullable NSString *)nameKey
                     images:(nullable NSArray<UIImage *> *)images
                  fileNames:(nullable NSArray<NSString *> *)fileNames
                 imageScale:(CGFloat)imageScale
                  imageType:(nullable NSString *)imageType
                   progress:(nullable void(^)(NSProgress *progress))progress
                    success:(nullable void(^)(id responseObject))success
                    failure:(nullable void(^)(NSError *error))failure;

/** 取消所有Http请求 */
+ (void)cancelAllRequest;

/** 取消指定URL的Http请求 */
+ (void)cancelRequestWithURL:(NSString *)url;

/** 实时获取网络状态 */
+ (void)getNetworkStatusWithBlock:(BRNetworkStatusBlock)networkStatusBlock;

/** 是否打开网络加载菊花(默认打开) */
+ (void)openNetworkActivityIndicator:(BOOL)open;

/** 判断当前是否有网络连接 */
+ (BOOL)isNetwork;

/** 判断当前是否是手机网络 */
+ (BOOL)isWWANNetwork;

/** 判断当前是否是WIFI网络 */
+ (BOOL)isWiFiNetwork;

@end

NS_ASSUME_NONNULL_END
