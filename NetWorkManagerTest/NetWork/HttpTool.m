//
//  HttpTool.m
//  AiBaoYun
//
//  Created by 任波 on 17/4/5.
//  Copyright © 2017年 aby. All rights reserved.
//

#import "HttpTool.h"
#import <AFNetworking.h>
#import "BRCache.h"
#import <UIImageView+YYWebImage.h>
#import "AppDelegate+Category.h"

/** 请求超时时间 */
static NSTimeInterval requestTimeout = 15.0f;

@implementation HttpTool

+ (AFHTTPSessionManager *)sharedManager {
    static AFHTTPSessionManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 创建请求管理者对象
        manager = [AFHTTPSessionManager manager];
        // 设置请求参数的格式：二进制格式
        manager.requestSerializer = [AFHTTPRequestSerializer serializer];
        // 设置服务器返回结果的格式：JSON格式
        manager.responseSerializer = [AFJSONResponseSerializer serializer];
        // 设置请求超时时间
        manager.requestSerializer.timeoutInterval = requestTimeout;
        // 配置响应序列化(设置请求接口回来的时候支持什么类型的数据,设置接收参数类型)
        manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json",
                                                                                  @"text/html",
                                                                                  @"text/json",
                                                                                  @"text/plain",
                                                                                  @"text/javascript",
                                                                                  @"text/xml",
                                                                                  @"image/*",
                                                                                  @"application/octet-stream",
                                                                                  @"application/zip",
                                                                                  @"text/text", nil];
    });
    return manager;
}

#pragma mark - get请求，不带缓存
+ (void)getWithUrl:(NSString *)url
            params:(NSDictionary *)params
           success:(BRHttpSuccessBlock)successBlock
           failure:(BRHttpFailureBlock)failureBlock {
    [self getWithUrl:url params:params responseCache:nil success:successBlock failure:failureBlock];
}

#pragma mark - post请求，不带缓存
+ (void)postWithUrl:(NSString *)url
             params:(NSDictionary *)params
            success:(BRHttpSuccessBlock)successBlock
            failure:(BRHttpFailureBlock)failureBlock {
    [self postWithUrl:url params:params responseCache:nil success:successBlock failure:failureBlock];
}

#pragma mark - get请求，带缓存
+ (void)getWithUrl:(NSString *)url
            params:(NSDictionary *)params
     responseCache:(BRHttpCacheBlock)responseCache
           success:(BRHttpSuccessBlock)successBlock
           failure:(BRHttpFailureBlock)failureBlock {
    //获取完整的url路径
    NSString *path = [AppBaseUrl stringByAppendingPathComponent:url];
    // 1.先加载本地缓存
    if (responseCache != nil) {
        // 获取缓存数据
        NSDictionary *dic = [BRCache getHttpCache:path params:params];
        responseCache(dic);
    }
    
    // 2.判断网络状态(如果没有网络则直接return)
    if (kIsNetwork == NO) {
        if (failureBlock) {
            NSError *netError = [NSError errorWithDomain:@"com.aby.ErrorDomain" code:-999 userInfo:@{ NSLocalizedDescriptionKey:@"网络出现错误，请检查网络连接"}];
            failureBlock(netError);
        }
        return;
    }
    
    // 3.开始请求(有网，则继续请求，然后刷新内容，刷新缓存)
    [[self sharedManager] GET:path parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        successBlock(responseObject);
        if (responseCache != nil) {
            // 4.更新缓存
            [BRCache saveHttpCache:responseObject url:path params:params];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failureBlock(error);
    }];
}

#pragma mark - post请求，带缓存
+ (void)postWithUrl:(NSString *)url
             params:(NSDictionary *)params
      responseCache:(BRHttpCacheBlock)responseCache
            success:(BRHttpSuccessBlock)successBlock
            failure:(BRHttpFailureBlock)failureBlock {
    // 获取完整的url路径
    NSString *path = [AppBaseUrl stringByAppendingPathComponent:url];
    // 1.先加载本地缓存
    if (responseCache != nil) {
        // 获取缓存数据
        NSDictionary *dic = [BRCache getHttpCache:path params:params];
        if (dic != nil) {
            responseCache(dic);
        }
    }
    // 2.判断网络状态(如果没有网络则直接return)
    if (kIsNetwork == NO) {
        if (failureBlock) {
            NSError *netError = [NSError errorWithDomain:@"com.aby.ErrorDomain" code:-999 userInfo:@{ NSLocalizedDescriptionKey:@"网络出现错误，请检查网络连接"}];
            failureBlock(netError);
        }
        return;
    }
    // 3.开始请求(有网，则继续请求，然后刷新内容，刷新缓存)
    [[self sharedManager] POST:path parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        successBlock(responseObject);
        if (responseCache != nil) {
            // 4.更新缓存
            [BRCache saveHttpCache:responseObject url:path params:params];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failureBlock(error);
    }];
}

#pragma mark - post请求
+ (void)MYPOST:(NSString *)url
             params:(NSDictionary *)params
            success:(BRHttpSuccessBlock)successBlock
            failure:(BRHttpFailureBlock)failureBlock {
    // 开始请求
    [[self sharedManager] POST:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        successBlock(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failureBlock(error);
    }];
}

#pragma mark - 下载文件
+ (void)downloadFileWithUrl:(NSString *)url
                   progress:(void(^)(NSProgress *progress))progress
                    success:(void(^)(NSString *filePath))success
                    failure:(void(^)(NSError *error))failure {
    //获取完整的url路径
    NSString * urlString = [AppBaseUrl stringByAppendingPathComponent:url];
    NSURL *URL = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    
    NSURLSessionDownloadTask *downloadTask = [[self sharedManager] downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        // 下载进度
        // progress.completedUnitCount: 当前大小;
        // Progress.totalUnitCount: 总大小
        progress(downloadProgress);
    } destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        //下载完后，实际下载在临时文件夹里；在这里需要保存到本地缓存文件夹里
        // 1.拼接缓存目录（保存到Download目录里）
        NSString *downloadDir = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"Download"];
        // 2.打开文件管理器
        NSFileManager *fileManager = [NSFileManager defaultManager];
        // 3.创建Download目录
        [fileManager createDirectoryAtPath:downloadDir withIntermediateDirectories:YES attributes:nil error:nil];
        // 4.拼接文件路径
        NSString *filePath = [downloadDir stringByAppendingPathComponent:response.suggestedFilename];
        // 5.返回文件位置的URL路径
        return [NSURL fileURLWithPath:filePath];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        if (!error) {
            // NSURL 转 NSString: filePath.path 或 filePath.absoluteString
            success(filePath.path);
        } else {
            failure(error);
        }
    }];
    // 开始下载
    [downloadTask resume];
}

#pragma mark - 下载图片(使用YYWebImage)，不给imageView赋值
+ (void)br_downloadImageWithUrl:(NSString *)url
                       progress:(void(^)(CGFloat progress))progress
                        success:(void(^)(UIImage *image))success
                         failed:(void(^)(NSError *error))failed {
    // YYWebImageOptionAvoidSetImage 下载完图片后不给ImageView赋值，需要我们手动去赋值。
    [[YYWebImageManager sharedManager] requestImageWithURL:[NSURL URLWithString:url] options:YYWebImageOptionAvoidSetImage progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        progress(receivedSize / (expectedSize * 1.0));
    } transform:nil completion:^(UIImage * _Nullable image, NSURL * _Nonnull url, YYWebImageFromType from, YYWebImageStage stage, NSError * _Nullable error) {
        if (error) {
            failed(error);
        } else {
            success(image);
        }
    }];
}

#pragma mark - 上传文件
+ (void)uploadFileWithUrl:(NSString *)Url
                   params:(id)params
                  nameKey:(NSString *)nameKey
                 filePath:(NSString *)filePath
                 progress:(void(^)(NSProgress *progress))progress
                  success:(void(^)(id responseObject))success
                  failure:(void(^)(NSError *error))failure {
    [[self sharedManager] POST:Url parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        NSError *error = nil;
        [formData appendPartWithFileURL:[NSURL URLWithString:filePath] name:nameKey error:&error];
        if (failure && error) {
            failure(error);
        }
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        //上传进度
        progress ? progress(uploadProgress) : nil;
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        success ? success(responseObject) : nil;
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failure ? failure(error) : nil;
    }];
}

#pragma mark - 上传单/多张图片
+ (void)uploadImagesWithUrl:(NSString *)Url
                     params:(id)params
                    nameKey:(NSString *)nameKey
                     images:(NSArray<UIImage *> *)images
                  fileNames:(NSArray<NSString *> *)fileNames
                 imageScale:(CGFloat)imageScale
                  imageType:(NSString *)imageType
                   progress:(void(^)(NSProgress *progress))progress
                    success:(void(^)(id responseObject))success
                    failure:(void(^)(NSError *error))failure {
    [[self sharedManager] POST:Url parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        for (NSUInteger i = 0; i < images.count; i++) {
            // 图片经过等比压缩后得到的二进制文件(imageData就是要上传的数据)
            NSData *imageData = UIImageJPEGRepresentation(images[i], imageScale ?: 1.0f);
            // 1.使用时间拼接上传图片名
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyyMMddHHmmss";
            NSString *currentTimeStr = [formatter stringFromDate:[NSDate date]];
            NSString *uploadFileName1 = [NSString stringWithFormat:@"%@%ld.%@", currentTimeStr, i, imageType?:@"jpg"];
            // 2.使用传入的图片名
            NSString *uploadFileName2 = [NSString stringWithFormat:@"%@.%@", fileNames[i], imageType?:@"jpg"];
            // 上传图片名
            NSString *uploadFileName = fileNames ? uploadFileName2 : uploadFileName1;
            // 上传图片类型
            NSString *uploadFileType = [NSString stringWithFormat:@"image/%@", imageType ?: @"jpg"];
            [formData appendPartWithFileData:imageData name:nameKey fileName:uploadFileName mimeType:uploadFileType];
        }
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        //上传进度
        progress ? progress(uploadProgress) : nil;
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        success ? success(responseObject) : nil;
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failure ? failure(error) : nil;
    }];
}


@end


#pragma mark - NSDictionary, NSArray的分类
/*
 ************************************************************************************
 * 新建NSDictionary与NSArray的分类, 控制台打印json数据中的中文
 ************************************************************************************
 */

#ifdef DEBUG
@implementation NSArray (BR)

- (NSString *)descriptionWithLocale:(id)locale {
    NSMutableString *strM = [NSMutableString stringWithString:@"(\n"];
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [strM appendFormat:@"\t%@,\n", obj];
    }];
    [strM appendString:@")"];
    
    return strM;
}

@end

@implementation NSDictionary (BR)

- (NSString *)descriptionWithLocale:(id)locale {
    NSMutableString *strM = [NSMutableString stringWithString:@"{\n"];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [strM appendFormat:@"\t%@ = %@;\n", key, obj];
    }];
    
    [strM appendString:@"}\n"];
    
    return strM;
}
@end
#endif

