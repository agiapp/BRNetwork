//
//  BRNetwork.h
//  BRNetworkDemo
//
//  Created by renbo on 2018/4/27.
//  Copyright © 2018年 irenb. All rights reserved.
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
typedef void (^BRHttpSuccessBlock)(NSURLSessionDataTask * _Nullable task, id _Nullable responseObject);
/** 失败的回调 */
typedef void (^BRHttpFailureBlock)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error);
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
 *  @param successBlock 请求成功的回调
 *  @param failureBlock 请求失败的回调
 */
+ (void)getWithUrl:(NSString *)url
            params:(nullable id)params
           headers:(nullable NSDictionary *)headers
           success:(nullable BRHttpSuccessBlock)successBlock
           failure:(nullable BRHttpFailureBlock)failureBlock;

/**
 *  POST请求方法
 *
 *  @param url 请求地址
 *  @param params 请求参数
 *  @param headers 请求头
 *  @param successBlock 请求成功的回调
 *  @param failureBlock 请求失败的回调
 */
+ (void)postWithUrl:(NSString *)url
            params:(nullable id)params
           headers:(nullable NSDictionary *)headers
           success:(nullable BRHttpSuccessBlock)successBlock
           failure:(nullable BRHttpFailureBlock)failureBlock;

/**
 *  网络请求方法
 *
 *  @param method 请求方法
 *  @param url 请求地址
 *  @param params 请求参数
 *  @param headers 请求头
 *  @param successBlock 请求成功的回调
 *  @param failureBlock 请求失败的回调
 */
+ (void)requestWithMethod:(BRRequestMethod)method
                      url:(NSString *)url
                   params:(nullable id)params
                  headers:(nullable NSDictionary *)headers
                  success:(nullable BRHttpSuccessBlock)successBlock
                  failure:(nullable BRHttpFailureBlock)failureBlock;

/**
 *  下载文件
 *
 *  @param url              请求地址
 *  @param cachePath        文件下载的缓存目录
 *  @param progressBlock    下载进度的回调
 *  @param successBlock     下载成功的回调
 *  @param failureBlock     下载失败的回调
 *
 */
+ (void)downloadFileWithUrl:(NSString *)url
                  cachePath:(NSString *)cachePath
                   progress:(nullable void(^)(NSProgress *progress))progressBlock
                    success:(nullable void(^)(NSString *filePath))successBlock
                    failure:(nullable void(^)(NSError *error))failureBlock;

/**
 *  上传文件（传入的是：文件二进制数据）
 *
 *  @param url              请求地址
 *  @param params           请求参数
 *  @param headers          请求头
 *  @param fileData         文件二进制数据
 *  @param name             表单中文件数据的参数名（即文件数据对应的key，如：file，upload等），服务器端接收文件的参数名
 *  @param fileName         自定义上传到服务器的文件名称
 *  @param mimeType         上传文件的 MIME 类型。MIME 类型描述了文件的内容类型。例如：image/jpeg 或 image/png 等。
 *  @param progressBlock    上传进度的回调
 *  @param successBlock     请求成功的回调
 *  @param failureBlock     请求失败的回调
 *
 */
+ (void)uploadFileWithUrl:(NSString *)url
                   params:(nullable id)params
                  headers:(nullable NSDictionary *)headers
                 fileData:(NSData *)fileData
                     name:(NSString *)name
                 fileName:(NSString *)fileName
                 mimeType:(NSString *)mimeType
                 progress:(nullable void(^)(NSProgress *progress))progressBlock
                  success:(nullable BRHttpSuccessBlock)successBlock
                  failure:(nullable BRHttpFailureBlock)failureBlock;

/**
 *  上传多个文件（传入的是：文件二进制数据）
 *
 *  @param url              请求地址
 *  @param params           请求参数
 *  @param headers          请求头
 *  @param fileDatas        文件二进制数据
 *  @param name             表单中文件数据的参数名（即文件数据对应的key，如：file，upload等），服务器端接收文件的参数名
 *  @param fileName         自定义上传到服务器的文件名称
 *  @param mimeType         上传文件的 MIME 类型。MIME 类型描述了文件的内容类型。例如：image/jpeg 或 image/png 等。
 *  @param progressBlock    上传进度的回调
 *  @param successBlock     请求成功的回调
 *  @param failureBlock     请求失败的回调
 *
 */
+ (void)uploadFilesWithUrl:(NSString *)url
                    params:(nullable id)params
                   headers:(nullable NSDictionary *)headers
                 fileDatas:(NSArray<NSData *> *)fileDatas
                      name:(NSString *)name
                  fileName:(NSString *)fileName
                  mimeType:(NSString *)mimeType
                  progress:(nullable void(^)(NSProgress *progress))progressBlock
                   success:(nullable BRHttpSuccessBlock)successBlock
                   failure:(nullable BRHttpFailureBlock)failureBlock;

/**
 *  上传文件（传入的是：本地文件路径，按文件原名称上传到服务器）
 *
 *  @param url              请求地址
 *  @param params           请求参数
 *  @param headers          请求头
 *  @param filePath         文件本地沙盒路径
 *  @param name             表单中文件数据的参数名（即文件数据对应的key，如：file，upload等），服务器端接收文件的参数名
 *  @param progressBlock    上传进度的回调
 *  @param successBlock     请求成功的回调
 *  @param failureBlock     请求失败的回调
 *
 */
+ (void)uploadFileWithUrl:(NSString *)url
                   params:(nullable id)params
                  headers:(nullable NSDictionary *)headers
                 filePath:(NSString *)filePath
                     name:(NSString *)name
                 progress:(nullable void(^)(NSProgress *progress))progressBlock
                  success:(nullable BRHttpSuccessBlock)successBlock
                  failure:(nullable BRHttpFailureBlock)failureBlock;

/**
 *  上传图片
 *
 *  @param url              请求地址
 *  @param params           请求参数
 *  @param headers          请求头
 *  @param image            图片对象
 *  @param name             表单中文件数据的参数名（即文件数据对应的key，如：file，upload等），服务器端接收文件的参数名
 *  @param progressBlock    上传进度的回调
 *  @param successBlock     请求成功的回调
 *  @param failureBlock     请求失败的回调
 *
 */
+ (void)uploadImageWithUrl:(NSString *)url
                    params:(nullable id)params
                   headers:(nullable NSDictionary *)headers
                     image:(UIImage *)image
                      name:(NSString *)name
                  progress:(nullable void(^)(NSProgress *progress))progressBlock
                   success:(nullable BRHttpSuccessBlock)successBlock
                   failure:(nullable BRHttpFailureBlock)failureBlock;

/**
 *  上传多个图片
 *
 *  @param url              请求地址
 *  @param params           请求参数
 *  @param headers          请求头
 *  @param images           图片对象数组
 *  @param name             表单中文件数据的参数名（即文件数据对应的key，如：file，upload等），服务器端接收文件的参数名
 *  @param progressBlock    上传进度的回调
 *  @param successBlock     请求成功的回调
 *  @param failureBlock     请求失败的回调
 *
 */
+ (void)uploadImagesWithUrl:(NSString *)url
                    params:(nullable id)params
                   headers:(nullable NSDictionary *)headers
                    images:(NSArray<UIImage *> *)images
                      name:(NSString *)name
                   progress:(nullable void(^)(NSProgress *progress))progressBlock
                    success:(nullable BRHttpSuccessBlock)successBlock
                    failure:(nullable BRHttpFailureBlock)failureBlock;

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
