//
//  HttpTool.h
//  AiBaoYun
//
//  Created by 任波 on 17/4/5.
//  Copyright © 2017年 aby. All rights reserved.
//

#import <Foundation/Foundation.h>

/** 成功的回调 */
typedef void (^BRHttpSuccessBlock)(id responseObject);
/** 失败的回调 */
typedef void (^BRHttpFailureBlock)(NSError *error);
/** 缓存的回调 */
typedef void (^BRHttpCacheBlock)(id responseCache);

@interface HttpTool : NSObject

/**
 *  get请求,无缓存
 *
 *  @param url              请求地址
 *  @param params           请求参数  (NSDictionary类型)
 *  @param successBlock     请求成功的回调  (返回NSDictionary 或 NSArray)
 *  @param failureBlock     请求失败的回调  (返回NSError)
 */

+ (void)getWithUrl:(NSString *)url
            params:(NSDictionary *)params
           success:(BRHttpSuccessBlock)successBlock
           failure:(BRHttpFailureBlock)failureBlock;

/**
 *  post网络请求,无缓存
 *
 *  @param url              请求地址
 *  @param params           请求参数  (NSDictionary类型)
 *  @param successBlock     请求成功的回调  (返回NSDictionary 或 NSArray)
 *  @param failureBlock     请求失败的回调  (返回NSError)
 */

+ (void)postWithUrl:(NSString *)url
             params:(NSDictionary *)params
            success:(BRHttpSuccessBlock)successBlock
            failure:(BRHttpFailureBlock)failureBlock;

/**
 *  get请求,自动缓存
 *
 *  @param url              请求地址
 *  @param params           请求参数  (NSDictionary类型)
 *  @param responseCache    缓存数据的回调
 *  @param successBlock     请求成功的回调  (返回NSDictionary 或 NSArray)
 *  @param failureBlock     请求失败的回调  (返回NSError)
 */

+ (void)getWithUrl:(NSString *)url
            params:(NSDictionary *)params
     responseCache:(BRHttpCacheBlock)responseCache
           success:(BRHttpSuccessBlock)successBlock
           failure:(BRHttpFailureBlock)failureBlock;

/**
 *  post网络请求
 *
 *  @param url              请求地址
 *  @param params           请求参数  (NSDictionary类型)
 *  @param responseCache    缓存数据的回调
 *  @param successBlock     请求成功的回调  (返回NSDictionary 或 NSArray)
 *  @param failureBlock     请求失败的回调  (返回NSError)
 */

+ (void)postWithUrl:(NSString *)url
             params:(NSDictionary *)params
      responseCache:(BRHttpCacheBlock)responseCache
            success:(BRHttpSuccessBlock)successBlock
            failure:(BRHttpFailureBlock)failureBlock;

/**
 *  post请求
 *
 *  @param url              请求地址
 *  @param params           请求参数  (NSDictionary类型)
 *  @param successBlock     请求成功的回调  (返回NSDictionary 或 NSArray)
 *  @param failureBlock     请求失败的回调  (返回NSError)
 */

+ (void)MYPOST:(NSString *)url
        params:(NSDictionary *)params
       success:(BRHttpSuccessBlock)successBlock
       failure:(BRHttpFailureBlock)failureBlock;


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
                   progress:(void(^)(NSProgress *progress))progress
                    success:(void(^)(NSString *filePath))success
                    failure:(void(^)(NSError *error))failure;

/**
 *  下载图片(使用YYWebImage)，不给imageView赋值
 *
 *  @param url       图片地址
 *  @param success   下载成功
 *  @param failed    下载失败
 */

+ (void)br_downloadImageWithUrl:(NSString *)url
                       progress:(void(^)(CGFloat progress))progress
                        success:(void(^)(UIImage *image))success
                         failed:(void(^)(NSError *error))failed;


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
                   params:(id)params
                  nameKey:(NSString *)nameKey
                 filePath:(NSString *)filePath
                 progress:(void(^)(NSProgress *progress))progress
                  success:(void(^)(id responseObject))success
                  failure:(void(^)(NSError *error))failure;

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
                     params:(id)params
                    nameKey:(NSString *)nameKey
                     images:(NSArray<UIImage *> *)images
                  fileNames:(NSArray<NSString *> *)fileNames
                 imageScale:(CGFloat)imageScale
                  imageType:(NSString *)imageType
                   progress:(void(^)(NSProgress *progress))progress
                    success:(void(^)(id responseObject))success
                    failure:(void(^)(NSError *error))failure;


@end
