//
//  BRNetwork.m
//  BRNetworkDemo
//
//  Created by 任波 on 2018/4/27.
//  Copyright © 2018年 91renb. All rights reserved.
//

#import "BRNetwork.h"
#import <AFNetworking.h>
#import <AFNetworkActivityIndicatorManager.h>
#import <AFNetworkReachabilityManager.h>
#import "BRCache.h"

#ifdef DEBUG
#define NSLog(FORMAT, ...) fprintf(stderr,"[%s:%d行] %s\n",[[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
#else
#define NSLog(...)
#endif

@implementation BRNetwork

static NSString *_baseUrl;
static BRNetworkStatus _netStatus;
static BRRequestMethod _requestMethod;
static NSDictionary *_baseParameters;
static BOOL _isOpenLog;
// 所有的请求task数组
static NSMutableArray *_allSessionTask;

#pragma mark - 所有的请求task数组
+ (NSMutableArray *)allSessionTask {
    if (!_allSessionTask) {
        _allSessionTask = [NSMutableArray array];
    }
    return _allSessionTask;
}

+ (AFHTTPSessionManager *)sharedManager {
    static AFHTTPSessionManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 创建请求管理者对象
        manager = [AFHTTPSessionManager manager];
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
        // 设置默认数据
        [self configDefaultData];
    });
    return manager;
}

#pragma mark - 设置默认值
+ (void)configDefaultData {
    // 设置请求参数的格式：二进制格式
    [self sharedManager].requestSerializer = [AFHTTPRequestSerializer serializer];
    // 设置服务器返回结果的格式：JSON格式
    [self sharedManager].responseSerializer = [AFJSONResponseSerializer serializer];
    // 设置请求超时时间
    [self sharedManager].requestSerializer.timeoutInterval = 30;
    // 开始监测网络状态
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    // 打开状态栏菊花
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    // 打开日志
    _isOpenLog = YES;
}

#pragma mark - 设置接口根路径
+ (void)setBaseUrl:(NSString *)baseUrl {
    baseUrl = baseUrl;
}

#pragma mark - 设置接口请求头
+ (void)setRequestHeaderDictionary:(NSDictionary *)dic; {
    for (NSString *key in dic.allKeys) {
        [[self sharedManager].requestSerializer setValue:dic[key] forHTTPHeaderField:key];
    }
}

#pragma mark - 设置请求超时时间(默认30s)
+ (void)setRequestTimeoutInterval:(NSTimeInterval)timeout {
    [self sharedManager].requestSerializer.timeoutInterval = timeout;
}

#pragma mark - 设置请求方法
+ (void)setRequestMethod:(BRRequestMethod)method {
    _requestMethod = method;
}

#pragma mark - 设置请求序列化类型
+ (void)setRequestSerializerType:(BRRequestSerializer)type {
    switch (type) {
        case BRRequestSerializerHTTP:
        {
            [self sharedManager].requestSerializer = [AFHTTPRequestSerializer serializer];
        }
            break;
        case BRRequestSerializerJSON:
        {
            [self sharedManager].requestSerializer = [AFJSONRequestSerializer serializer];
        }
            break;
            
        default:
            break;
    }
}

#pragma mark - 设置响应序列化类型
+ (void)setResponseSerializerType:(BRResponseSerializer)type {
    switch (type) {
        case BRResponseSerializerHTTP:
        {
            [self sharedManager].responseSerializer = [AFHTTPResponseSerializer serializer];
        }
            break;
        case BRResponsetSerializerJSON:
        {
            [self sharedManager].responseSerializer = [AFJSONResponseSerializer serializer];
        }
            break;
            
        default:
            break;
    }
}

#pragma mark - 设置接口基本参数(如:用户ID, Token)
+ (void)setBaseParameters:(NSDictionary *)params {
    _baseParameters = params;
}

#pragma mark - 输出Log信息开关
+ (void)setIsOpenLog:(BOOL)isOpenLog {
    _isOpenLog = isOpenLog;
}

#pragma mark - 验证https证书
// 参考链接:http://blog.csdn.net/syg90178aw/article/details/52839103
+ (void)setSecurityPolicyWithCerPath:(NSString *)cerPath validatesDomainName:(BOOL)validatesDomainName {
    // 先导入证书 证书由服务端生成，具体由服务端人员操作
    // NSString *cerPath = [[NSBundle mainBundle] pathForResource:@"xxx" ofType:@"cer"]; //证书的路径
    NSData *cerData = [NSData dataWithContentsOfFile:cerPath];
    // 使用证书验证模式：AFSSLPinningModeCertificate
    AFSecurityPolicy *securitypolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    // 是否允许无效证书（也就是自建的证书），默认为NO；如果需要验证自建证书，需要设置为YES
    securitypolicy.allowInvalidCertificates = YES;
    // 是否需要验证域名，默认为YES。假如证书的域名与你请求的域名不一致，需把该项设置为NO；
    securitypolicy.validatesDomainName = validatesDomainName;
    securitypolicy.pinnedCertificates = [[NSSet alloc] initWithObjects:cerData, nil];
    [self sharedManager].securityPolicy = securitypolicy;
}

#pragma mark - 是否打开网络加载菊花(默认打开)
+ (void)openNetworkActivityIndicator:(BOOL)open {
    [[AFNetworkActivityIndicatorManager sharedManager]setEnabled:open];
}

#pragma mark - 取消所有Http请求
+ (void)cancelAllRequest {
    @synchronized (self) {
        [[self allSessionTask] enumerateObjectsUsingBlock:^(NSURLSessionTask  *_Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            [task cancel];
        }];
        [[self allSessionTask] removeAllObjects];
    }
}

#pragma mark - 取消指定URL的Http请求
+ (void)cancelRequestWithURL:(NSString *)url {
    if (!url) { return; }
    @synchronized (self) {
        [[self allSessionTask] enumerateObjectsUsingBlock:^(NSURLSessionTask  *_Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([task.currentRequest.URL.absoluteString hasPrefix:url]) {
                [task cancel];
                [[self allSessionTask] removeObject:task];
                *stop = YES;
            }
        }];
    }
}

#pragma mark - 请求方法
+ (void)requestWithMethod:(BRRequestMethod)method
                      url:(NSString *)url
                   params:(NSDictionary *)params
              cachePolicy:(BRCachePolicy)cachePolicy
                  success:(BRHttpSuccessBlock)successBlock
                  failure:(BRHttpFailureBlock)failureBlock {
    if (_baseUrl && _baseUrl.length > 0) {
        // 获取完整的url路径
        url = [NSString stringWithFormat:@"%@%@", _baseUrl, url];
    }
    if (_baseParameters.count > 0) {
        NSMutableDictionary *mutableDic = [NSMutableDictionary dictionaryWithDictionary:params];
        // 添加基本参数/公共参数
        [mutableDic addEntriesFromDictionary:_baseParameters];
        params = [mutableDic copy];
    }
    if (_isOpenLog) {
        NSLog(@"\n%@：请求参数%@\n", url, params);
    }
    
    if (cachePolicy == BRCachePolicyNetworkOnly) {
        [self requestWithMethod:method url:url params:params success:successBlock failure:failureBlock];
    } else if (cachePolicy == BRCachePolicyNetworkAndSaveCache) {
        [self requestWithMethod:method url:url params:params success:^(id responseObject) {
            // 更新本地缓存
            [BRCache saveHttpCache:responseObject url:url params:params];
            successBlock ? successBlock(responseObject) : nil;
        } failure:^(NSError *error) {
            failureBlock ? failureBlock(error) : nil;
        }];
    } else if (cachePolicy == BRCachePolicyNetworkElseCache) {
        [self requestWithMethod:method url:url params:params success:^(id responseObject) {
            successBlock ? successBlock(responseObject) : nil;
        } failure:^(NSError *error) {
            [BRCache getHttpCache:url params:params block:^(id<NSCoding> object) {
                if (object) {
                    successBlock ? successBlock(object) : nil;
                } else {
                    failureBlock ? failureBlock(error) : nil;
                }
            }];
        }];
    } else if (cachePolicy == BRCachePolicyCacheOnly) {
        [BRCache getHttpCache:url params:params block:^(id<NSCoding> object) {
            successBlock ? successBlock(object) : nil;
        }];
    } else if (cachePolicy == BRCachePolicyCacheElseNetwork) {
        // 先从缓存读取数据
        [BRCache getHttpCache:url params:params block:^(id<NSCoding> object) {
            if (object) {
                successBlock ? successBlock(object) : nil;
            } else {
                // 如果没有缓存再从网络获取
                [self requestWithMethod:method url:url params:params success:^(id responseObject) {
                    successBlock ? successBlock(responseObject) : nil;
                } failure:^(NSError *error) {
                    failureBlock ? failureBlock(error) : nil;
                }];
            }
        }];
    } else if (cachePolicy == BRCachePolicyCacheThenNetwork) {
        // 先从缓存读取数据（这种情况successBlock调用两次）
        [BRCache getHttpCache:url params:params block:^(id<NSCoding> object) {
            successBlock ? successBlock(object) : nil;
            // 再从网络获取
            [self requestWithMethod:method url:url params:params success:^(id responseObject) {
                [BRCache saveHttpCache:responseObject url:url params:params];
                successBlock ? successBlock(responseObject) : nil;
            } failure:^(NSError *error) {
                failureBlock ? failureBlock(error) : nil;
            }];
        }];
    } else {
        // 未知缓存策略 (使用BRCachePolicyNetworkOnly)
        [self requestWithMethod:method url:url params:params success:successBlock failure:failureBlock];
    }
}

#pragma mark - 网络请求处理
+ (void)requestWithMethod:(BRRequestMethod)method
                      url:(NSString *)url
                   params:(NSDictionary *)params
                  success:(BRHttpSuccessBlock)successBlock
                  failure:(BRHttpFailureBlock)failureBlock {
    [self dataTaskWithMethod:method url:url params:params success:^(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject) {
        if (_isOpenLog) {
            NSLog(@"请求结果：%@", responseObject);
        }
        [[self allSessionTask] removeObject:task];
        successBlock ? successBlock(responseObject) : nil;
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (_isOpenLog) {
            NSLog(@"请求失败：%@", error);
        }
        failureBlock ? failureBlock(error) : nil;
        [[self allSessionTask] removeObject:task];
    }];
}

#pragma mark - 请求任务
+ (void)dataTaskWithMethod:(BRRequestMethod)method
                      url:(NSString *)url
                   params:(NSDictionary *)params
                  success:(void (^)(NSURLSessionDataTask * _Nonnull, id _Nullable))success
                  failure:(void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure {
    NSURLSessionTask *sessionTask = nil;
    switch (method) {
        case BRRequestMethodGET:
        {
            sessionTask = [[self sharedManager] GET:url parameters:params progress:nil success:success failure:failure];
        }
            break;
        case BRRequestMethodPOST:
        {
            sessionTask = [[self sharedManager] POST:url parameters:params progress:nil success:success failure:failure];
        }
            break;
        case BRRequestMethodHEAD:
        {
            sessionTask = [[self sharedManager] HEAD:url parameters:params success:nil failure:failure];
        }
            break;
        case BRRequestMethodPUT:
        {
            sessionTask = [[self sharedManager] PUT:url parameters:params success:nil failure:failure];
        }
            break;
        case BRRequestMethodPATCH:
        {
            sessionTask = [[self sharedManager] PATCH:url parameters:params success:nil failure:failure];
        }
            break;
        case BRRequestMethodDELETE:
        {
            sessionTask = [[self sharedManager] DELETE:url parameters:params success:nil failure:failure];
        }
            break;
            
        default:
            break;
    }
    //添加最新的sessionTask到数组
    sessionTask ? [[self allSessionTask] addObject:sessionTask] : nil;
}

#pragma mark - 下载文件
+ (void)downloadFileWithUrl:(NSString *)url
                   progress:(void(^)(NSProgress *progress))progress
                    success:(void(^)(NSString *filePath))success
                    failure:(void(^)(NSError *error))failure {
    NSURL *URL = [NSURL URLWithString:url];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    __block NSURLSessionDownloadTask *downloadTask = [[self sharedManager] downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        // 下载进度
        // progress.completedUnitCount: 当前大小;
        // Progress.totalUnitCount: 总大小
        if (_isOpenLog) {
            NSLog(@"下载进度：%.2f%%",100.0 * downloadProgress.completedUnitCount / downloadProgress.totalUnitCount);
        }
        progress ? progress(downloadProgress) : nil;
    } destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        // 下载完后，实际下载在临时文件夹里；在这里需要保存到本地缓存文件夹里
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
        [[self allSessionTask] removeObject:downloadTask];
        if (!error) {
            // NSURL 转 NSString: filePath.path 或 filePath.absoluteString
            success ? success(filePath.path) : nil;
        } else {
            failure(error);
        }
    }];
    // 开始下载
    [downloadTask resume];
    // 添加sessionTask到数组
    downloadTask ? [[self allSessionTask] addObject:downloadTask] : nil;
}

#pragma mark - 上传文件
+ (void)uploadFileWithUrl:(NSString *)Url
                   params:(id)params
                  nameKey:(NSString *)nameKey
                 filePath:(NSString *)filePath
                 progress:(void(^)(NSProgress *progress))progress
                  success:(void(^)(id responseObject))success
                  failure:(void(^)(NSError *error))failure {
    NSURLSessionTask *sessionTask = [[self sharedManager] POST:Url parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        NSError *error = nil;
        [formData appendPartWithFileURL:[NSURL URLWithString:filePath] name:nameKey error:&error];
        if (failure && error) {
            failure(error);
        }
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        //上传进度
        progress ? progress(uploadProgress) : nil;
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [[self allSessionTask] removeObject:task];
        success ? success(responseObject) : nil;
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [[self allSessionTask] removeObject:task];
        failure ? failure(error) : nil;
    }];
    // 添加最新的sessionTask到数组
    sessionTask ? [[self allSessionTask] addObject:sessionTask] : nil;
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
    NSURLSessionTask *sessionTask = [[self sharedManager] POST:Url parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        // 循环遍历上传图片
        [images enumerateObjectsUsingBlock:^(UIImage * _Nonnull image, NSUInteger idx, BOOL * _Nonnull stop) {
            // 图片经过等比压缩后得到的二进制文件(imageData就是要上传的数据)
            NSData *imageData = UIImageJPEGRepresentation(image, imageScale ?: 1.0f);
            // 1.使用时间拼接上传图片名
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyyMMddHHmmss";
            NSString *currentTimeStr = [formatter stringFromDate:[NSDate date]];
            NSString *uploadFileName1 = [NSString stringWithFormat:@"%@%ld.%@", currentTimeStr, idx, imageType?:@"jpg"];
            // 2.使用传入的图片名
            NSString *uploadFileName2 = [NSString stringWithFormat:@"%@.%@", fileNames[idx], imageType?:@"jpg"];
            // 上传图片名
            NSString *uploadFileName = fileNames ? uploadFileName2 : uploadFileName1;
            // 上传图片类型
            NSString *uploadFileType = [NSString stringWithFormat:@"image/%@", imageType ?: @"jpg"];
            
            [formData appendPartWithFileData:imageData name:nameKey fileName:uploadFileName mimeType:uploadFileType];
        }];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        //上传进度
        progress ? progress(uploadProgress) : nil;
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [[self allSessionTask] removeObject:task];
        success ? success(responseObject) : nil;
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [[self allSessionTask] removeObject:task];
        failure ? failure(error) : nil;
    }];
    // 添加最新的sessionTask到数组
    sessionTask ? [[self allSessionTask] addObject:sessionTask] : nil;
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
