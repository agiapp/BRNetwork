//
//  HttpTool.m
//  BRNetworkDemo
//
//  Created by 任波 on 2018/4/8.
//  Copyright © 2018年 91renb. All rights reserved.
//

#import "HttpTool.h"
#import <AFNetworking.h>
#import <AFNetworkActivityIndicatorManager.h>
#import <AFNetworkReachabilityManager.h>
#import "BRCache.h"
#import "APIConfig.h"

typedef NS_ENUM(NSUInteger, BRNetworkStatus) {
    BRNetworkStatusUnknown,           // 未知网络
    BRNetworkStatusNotReachable,      // 无网络
    BRNetworkStatusReachableViaWWAN,  // 手机网络
    BRNetworkStatusReachableViaWiFi   // WIFI网络
};

/** 网络连接状态 */
static BRNetworkStatus _netStatus;

/** 请求超时时间 */
static NSTimeInterval requestTimeout = 20.0f;

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
        // 验证https证书，如不需要屏蔽这块
        NSString * cerPath = [[NSBundle mainBundle] pathForResource:@"xxxx" ofType:@"cer"];
        NSData *cerData = [NSData dataWithContentsOfFile:cerPath];
        manager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate withPinnedCertificates:[[NSSet alloc] initWithObjects:cerData, nil]];
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
    if ([self isNetwork] == NO) {
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
    if ([self isNetwork] == NO) {
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

#pragma mark - 开启网络状态监控
+ (void)openNetworkStatusMonitoring {
    // 打开状态栏的等待菊花
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    // 1.创建网络监听管理者
    AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
    // 2.设置网络状态改变后的处理
    [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        // 当网络状态改变了, 就会调用这个block
        switch (status) {
            case AFNetworkReachabilityStatusUnknown:
                NSLog(@"当前网络未知");
                _netStatus = BRNetworkStatusUnknown;
                break;
            case AFNetworkReachabilityStatusNotReachable:
                NSLog(@"当前无网络");
                _netStatus = BRNetworkStatusNotReachable;
                break;
            case AFNetworkReachabilityStatusReachableViaWiFi:
                NSLog(@"当前是wifi环境");
                _netStatus = BRNetworkStatusReachableViaWiFi;
                break;
            case AFNetworkReachabilityStatusReachableViaWWAN:
                NSLog(@"当前是蜂窝网络");
                _netStatus = BRNetworkStatusReachableViaWWAN;
                break;
            default:
                break;
        }
    }];
    // 3.开启网络监听
    [manager startMonitoring];
}

/** 判断当前是否有网络连接 */
+ (BOOL)isNetwork {
    return [AFNetworkReachabilityManager sharedManager].reachable;
}

/** 判断当前是否是手机网络 */
+ (BOOL)isWWANNetwork {
    return [AFNetworkReachabilityManager sharedManager].reachableViaWWAN;
}

/** 判断当前是否是WIFI网络 */
+ (BOOL)isWiFiNetwork {
    return [AFNetworkReachabilityManager sharedManager].reachableViaWiFi;
}

@end


#pragma mark - 新建 NSDictionary 分类, 控制台打印json格式（字典转json）

#ifdef DEBUG

@implementation NSDictionary (BRLog)

- (NSString *)descriptionWithLocale:(id)locale {
    NSString *logString = nil;
    @try {
        logString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:self options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding];
    } @catch (NSException *exception) {
        logString = [NSString stringWithFormat:@"reason: %@ \n%@", exception.reason, self.description];
    } @finally {
        
    }
    return logString;
}

@end

#endif
