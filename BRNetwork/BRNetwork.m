//
//  BRNetwork.m
//  BRNetworkDemo
//
//  Created by 任波 on 2018/4/27.
//  Copyright © 2018年 91renb. All rights reserved.
//

#import "BRNetwork.h"
#import "BRCache.h"
#if __has_include(<AFNetworking/AFNetworking.h>)
#import <AFNetworking/AFNetworking.h>
#else
#import "AFNetworking.h"
#endif
// 电池条上网络活动提示(菊花转动)
#import "AFNetworkActivityIndicatorManager.h"


#ifdef __OBJC__

// 日志输出宏定义
#ifdef DEBUG
// 调试状态
#define BRLog(FORMAT, ...) fprintf(stderr, "%s:[第%d行]\t%s\n", [[[NSString stringWithUTF8String: __FILE__] lastPathComponent] UTF8String], __LINE__, [[NSString stringWithFormat: FORMAT, ## __VA_ARGS__] UTF8String]);
#else
// 发布状态
#define BRLog(...)
#endif

#endif


@implementation BRNetwork

static NSString *_baseUrl;
static NSDictionary *_baseParameters;   // 公共参数
static NSDictionary *_encodeParameters; // 加密参数
static BOOL _isOpenLog;       // 是否开启日志打印
static NSString *_logString;  // 日志字符串
static BOOL _isNeedEncry;     // 是否需要加密传输
static BRCachePolicy _cachePolicy; // 缓存策略
// 所有的请求task数组
static NSMutableArray *_allSessionTask;
static AFHTTPSessionManager *_sessionManager;

#pragma mark - 所有的请求task数组
+ (NSMutableArray *)allSessionTask {
    if (!_allSessionTask) {
        _allSessionTask = [NSMutableArray array];
    }
    return _allSessionTask;
}

#pragma mark - 开始监测网络状态
+ (void)load {
    // 开始监测网络状态
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
}

+ (void)initialize {
    // 创建请求管理者对象
    _sessionManager = [AFHTTPSessionManager manager];
    // 配置响应序列化(设置请求接口回来的时候支持什么类型的数据,设置接收参数类型)
    _sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json",
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
}

#pragma mark - 设置默认值
+ (void)configDefaultData {
    // 设置请求参数的格式：二进制格式
    _sessionManager.requestSerializer = [AFHTTPRequestSerializer serializer];
    // 设置服务器返回结果的格式：JSON格式
    _sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
    // 最大请求并发任务数
    //_sessionManager.operationQueue.maxConcurrentOperationCount = 5;
    // 设置请求超时时间
    _sessionManager.requestSerializer.timeoutInterval = 30;
    // 打开状态栏菊花
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    // 打开日志
    _isOpenLog = YES;
    // 默认不加密传输
    _isNeedEncry = NO;
}

#pragma mark - 设置接口根路径
+ (void)setBaseUrl:(NSString *)baseUrl {
    _baseUrl = baseUrl;
}

#pragma mark - 设置接口基本参数/公共参数 (如:用户ID, Token)
+ (void)setBaseParameters:(NSDictionary *)params {
    _baseParameters = params;
}

#pragma mark - 加密接口参数/加密Body
+ (void)setEncodeParameters:(NSDictionary *)params {
    _encodeParameters = params;
}

#pragma mark - 是否开启日志打印
+ (void)setIsOpenLog:(BOOL)isOpenLog {
    _isOpenLog = isOpenLog;
}

#pragma mark - 是否需要加密传输
+ (void)setIsNeedEncry:(BOOL)isNeedEncry {
    _isNeedEncry = isNeedEncry;
}

#pragma mark - 设置请求头（额外的HTTP请求头字段，这里可以给请求头添加加密键值对，即加密header/签名）
+ (void)setRequestHeaderFieldValueDictionary:(NSDictionary *)dic {
    if (_isOpenLog) {
        _logString = [NSString stringWithFormat:@"【请求头】：%@\n", dic];
    }
    if (dic && dic.count > 0) {
        for (NSString *key in dic.allKeys) {
            [_sessionManager.requestSerializer setValue:dic[key] forHTTPHeaderField:key];
        }
    }
}

#pragma mark - 设置请求超时时间(默认30s)
+ (void)setRequestTimeoutInterval:(NSTimeInterval)timeout {
    _sessionManager.requestSerializer.timeoutInterval = timeout;
}

#pragma mark - 设置请求序列化类型
+ (void)setRequestSerializerType:(BRRequestSerializer)type {
    switch (type) {
        case BRRequestSerializerHTTP:
        {
            _sessionManager.requestSerializer = [AFHTTPRequestSerializer serializer];
        }
            break;
        case BRRequestSerializerJSON:
        {
            _sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
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
            _sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
        }
            break;
        case BRResponsetSerializerJSON:
        {
            _sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
        }
            break;
            
        default:
            break;
    }
}

#pragma mark - 验证https证书
// 参考链接:http://blog.csdn.net/syg90178aw/article/details/52839103
+ (void)setSecurityPolicyWithCerPath:(NSString *)cerPath validatesDomainName:(BOOL)validatesDomainName {
    // 先导入证书 证书由服务端生成，具体由服务端人员操作
    // NSString *cerPath = [[NSBundle mainBundle] pathForResource:@"xxx" ofType:@"cer"]; // CA证书地址
    // 获取CA证书数据
    NSData *cerData = [NSData dataWithContentsOfFile:cerPath];
    // 使用证书验证模式：AFSSLPinningModeCertificate
    AFSecurityPolicy *securitypolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    // 是否允许无效证书（也就是自建的证书），默认为NO；如果需要验证自建证书，需要设置为YES
    securitypolicy.allowInvalidCertificates = YES;
    // 是否需要验证域名，默认为YES。假如证书的域名与你请求的域名不一致，需把该项设置为NO；
    securitypolicy.validatesDomainName = validatesDomainName;
    // 根据验证模式来返回用于验证服务器的证书
    securitypolicy.pinnedCertificates = [[NSSet alloc] initWithObjects:cerData, nil];
    _sessionManager.securityPolicy = securitypolicy;
}

/** 设置接口数据缓存 */
+ (void)setCachePolicy:(BRCachePolicy)cachePolicy {
    _cachePolicy = cachePolicy;
}

/**
 *  设置接口数据缓存
 *
 *  @param cachePolicy 缓存策略
 *  @param timeLimit   缓存过期时间（单位：秒）
 */
+ (void)setCachePolicy:(BRCachePolicy)cachePolicy timeLimit:(NSTimeInterval)timeLimit {
    _cachePolicy = cachePolicy;
    [BRCache setExpirationTime:timeLimit];
}

#pragma mark - GET请求方法
+ (void)getWithUrl:(NSString *)url
            params:(NSDictionary *)params
           success:(BRHttpSuccessBlock)successBlock
           failure:(BRHttpFailureBlock)failureBlock {
    [self requestWithMethod:BRRequestMethodGET url:url params:params success:successBlock failure:failureBlock];
}

#pragma mark - POST请求方法
+ (void)postWithUrl:(NSString *)url
             params:(NSDictionary *)params
            success:(BRHttpSuccessBlock)successBlock
            failure:(BRHttpFailureBlock)failureBlock {
    [self requestWithMethod:BRRequestMethodPOST url:url params:params success:successBlock failure:failureBlock];
}

#pragma mark - 网络请求公共方法
+ (void)requestWithMethod:(BRRequestMethod)method
                      url:(NSString *)url
                   params:(NSDictionary *)params
                  success:(BRHttpSuccessBlock)successBlock
                  failure:(BRHttpFailureBlock)failureBlock {
    if (!(url && [url hasPrefix:@"http"]) && _baseUrl && _baseUrl.length > 0) {
        // 获取完整的url路径
        url = [NSString stringWithFormat:@"%@%@", _baseUrl, url];
    }
    if (_baseParameters.count > 0) {
        NSMutableDictionary *mutableDic = [NSMutableDictionary dictionaryWithDictionary:params];
        // 添加基本参数/公共参数
        [mutableDic addEntriesFromDictionary:_baseParameters];
        params = [mutableDic copy];
    }
    if (_isNeedEncry && _encodeParameters.count > 0) {
        params = _encodeParameters;
    }
    if (_isOpenLog) {
        _logString = [NSString stringWithFormat:@"[%@]\n%@【请求参数】：%@\n", url, _logString, params];
    }
    if (_cachePolicy == BRCachePolicyNetworkOnly) {
        [self httpRequestWithMethod:method url:url params:params success:successBlock failure:failureBlock];
    } else if (_cachePolicy == BRCachePolicyNetworkAndSaveCache) {
        [self httpRequestWithMethod:method url:url params:params success:^(id responseObject) {
            // 更新缓存
            [BRCache saveHttpCache:responseObject url:url params:params];
            successBlock ? successBlock(responseObject) : nil;
        } failure:^(NSError *error) {
            failureBlock ? failureBlock(error) : nil;
        }];
    } else if (_cachePolicy == BRCachePolicyNetworkElseCache) {
        [self httpRequestWithMethod:method url:url params:params success:^(id responseObject) {
            // 更新缓存
            [BRCache saveHttpCache:responseObject url:url params:params];
            successBlock ? successBlock(responseObject) : nil;
        } failure:^(NSError *error) {
            [BRCache getHttpCache:url params:params block:^(id<NSCoding> object) {
                if (object) {
                    if (_isOpenLog) BRLog(@"%@", [NSString stringWithFormat:@"%@【缓存内容】：%@\n\n-------------------------------------------------\n\n", _logString, object]);
                    successBlock ? successBlock(object) : nil;
                } else {
                    if (_isOpenLog) BRLog(@"%@", [NSString stringWithFormat:@"%@【缓存内容】：%@\n\n-------------------------------------------------\n\n", _logString, object]);
                    failureBlock ? failureBlock(error) : nil;
                }
            }];
        }];
    } else if (_cachePolicy == BRCachePolicyCacheOnly) {
        [BRCache getHttpCache:url params:params block:^(id<NSCoding> object) {
            if (_isOpenLog) BRLog(@"%@", [NSString stringWithFormat:@"%@【缓存内容】：%@\n\n-------------------------------------------------\n\n", _logString, object]);
            successBlock ? successBlock(object) : nil;
        }];
    } else if (_cachePolicy == BRCachePolicyCacheElseNetwork) {
        // 先从缓存读取数据
        [BRCache getHttpCache:url params:params block:^(id<NSCoding> object) {
            if (object) {
                if (_isOpenLog) BRLog(@"%@", [NSString stringWithFormat:@"%@【缓存内容】：%@\n\n-------------------------------------------------\n\n", _logString, object]);
                successBlock ? successBlock(object) : nil;
            } else {
                // 如果没有缓存再从网络获取
                [self httpRequestWithMethod:method url:url params:params success:^(id responseObject) {
                    // 更新缓存
                    [BRCache saveHttpCache:responseObject url:url params:params];
                    successBlock ? successBlock(responseObject) : nil;
                } failure:^(NSError *error) {
                    failureBlock ? failureBlock(error) : nil;
                }];
            }
        }];
    } else if (_cachePolicy == BRCachePolicyCacheAndNetwork) {
        // 先从缓存读取数据
        [BRCache getHttpCache:url params:params block:^(id<NSCoding> object) {
            if (object) {
                if (_isOpenLog) BRLog(@"%@", [NSString stringWithFormat:@"%@【缓存内容】：%@\n\n-------------------------------------------------\n\n", _logString, object]);
                successBlock ? successBlock(object) : nil;
            }
            // 同时再从网络获取
            [self httpRequestWithMethod:method url:url params:params success:^(id responseObject) {
                // 更新本地缓存
                [BRCache saveHttpCache:responseObject url:url params:params];
                // 如果本地不存在缓存，就获取网络数据
                if (!object) {
                    successBlock ? successBlock(responseObject) : nil;
                }
            } failure:^(NSError *error) {
                failureBlock ? failureBlock(error) : nil;
            }];
        }];
    } else if (_cachePolicy == BRCachePolicyCacheThenNetwork) {
        // 先从缓存读取数据（这种情况successBlock调用两次）
        [BRCache getHttpCache:url params:params block:^(id<NSCoding> object) {
            if (object) {
                if (_isOpenLog) BRLog(@"%@", [NSString stringWithFormat:@"%@【缓存内容】：%@\n\n-------------------------------------------------\n\n", _logString, object]);
                successBlock ? successBlock(object) : nil;
            }
            // 再从网络获取
            [self httpRequestWithMethod:method url:url params:params success:^(id responseObject) {
                // 更新缓存
                [BRCache saveHttpCache:responseObject url:url params:params];
                successBlock ? successBlock(responseObject) : nil;
            } failure:^(NSError *error) {
                failureBlock ? failureBlock(error) : nil;
            }];
        }];
    } else {
        // 未知缓存策略 (使用BRCachePolicyNetworkOnly)
        [self httpRequestWithMethod:method url:url params:params success:successBlock failure:failureBlock];
    }
}

#pragma mark - 网络请求处理
+ (void)httpRequestWithMethod:(BRRequestMethod)method
                          url:(NSString *)url
                       params:(NSDictionary *)params
                      success:(BRHttpSuccessBlock)successBlock
                      failure:(BRHttpFailureBlock)failureBlock {
    [self dataTaskWithMethod:method url:url params:params success:^(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject) {
        // 响应序列化类型是HTTP时，请求结果输出的是二进制数据
        if (![NSJSONSerialization isValidJSONObject:responseObject]) {
            NSError *error = nil;
            // 将二进制数据序列化成JSON数据
            id obj = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:&error];
            if (error) {
                NSLog(@"二进制数据序列化成JSON数据失败：%@", error);
            } else {
                responseObject = obj;
            }
        }
        if (_isOpenLog) BRLog(@"%@", [NSString stringWithFormat:@"%@【请求成功】：%@\n\n-------------------------------------------------\n\n", _logString, responseObject]);
        [[self allSessionTask] removeObject:task];
        successBlock ? successBlock(responseObject) : nil;
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (_isOpenLog) BRLog(@"%@", [NSString stringWithFormat:@"%@【请求失败】：%@\n\n-------------------------------------------------\n\n", _logString, error]);
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
    if (method == BRRequestMethodGET) {
        sessionTask = [_sessionManager GET:url parameters:params progress:nil success:success failure:failure];
    } else if (method == BRRequestMethodPOST) {
        sessionTask = [_sessionManager POST:url parameters:params progress:nil success:success failure:failure];
    } else if (method == BRRequestMethodHEAD) {
        sessionTask = [_sessionManager HEAD:url parameters:params success:nil failure:failure];
    } else if (method == BRRequestMethodPUT) {
        sessionTask = [_sessionManager PUT:url parameters:params success:nil failure:failure];
    } else if (method == BRRequestMethodPATCH) {
        sessionTask = [_sessionManager PATCH:url parameters:params success:nil failure:failure];
    } else if (method == BRRequestMethodDELETE) {
        sessionTask = [_sessionManager DELETE:url parameters:params success:nil failure:failure];
    } else {
        sessionTask = [_sessionManager GET:url parameters:params progress:nil success:success failure:failure];
    }
    
    // 添加最新的sessionTask到数组
    sessionTask ? [[self allSessionTask] addObject:sessionTask] : nil;
}

#pragma mark - 下载文件
+ (void)downloadFileWithUrl:(NSString *)url
                   progress:(void(^)(NSProgress *progress))progress
                    success:(void(^)(NSString *filePath))success
                    failure:(void(^)(NSError *error))failure {
    NSURL *URL = [NSURL URLWithString:url];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    __block NSURLSessionDownloadTask *downloadTask = [_sessionManager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        // 下载进度
        // progress.completedUnitCount: 当前大小;
        // Progress.totalUnitCount: 总大小
        if (_isOpenLog) NSLog(@"下载进度：%.2f%%",100.0 * downloadProgress.completedUnitCount / downloadProgress.totalUnitCount);
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
    NSURLSessionTask *sessionTask = [_sessionManager POST:Url parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
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
    NSURLSessionTask *sessionTask = [_sessionManager POST:Url parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        // 循环遍历上传图片
        [images enumerateObjectsUsingBlock:^(UIImage * _Nonnull image, NSUInteger idx, BOOL * _Nonnull stop) {
            // 图片经过等比压缩后得到的二进制文件(imageData就是要上传的数据)
            NSData *imageData = UIImageJPEGRepresentation(image, imageScale ?: 1.0f);
            // 1.使用时间拼接上传图片名
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyyMMddHHmmss";
            NSString *currentTimeStr = [formatter stringFromDate:[NSDate date]];
            NSString *uploadFileName1 = [NSString stringWithFormat:@"%@%@.%@", currentTimeStr, @(idx), imageType?:@"jpg"];
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

#pragma mark - 取消所有Http请求
+ (void)cancelAllRequest {
    // 锁操作
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
    // 锁操作
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

#pragma mark - 实时获取网络状态
+ (void)getNetworkStatusWithBlock:(BRNetworkStatusBlock)networkStatusBlock {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 1.创建网络监听管理者
        AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
        // 2.设置网络状态改变后的处理
        [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            // 当网络状态改变了, 就会调用这个block
            switch (status) {
                case AFNetworkReachabilityStatusUnknown:
                    if (_isOpenLog) NSLog(@"当前网络未知");
                    networkStatusBlock ? networkStatusBlock(BRNetworkStatusUnknown) : nil;
                    break;
                case AFNetworkReachabilityStatusNotReachable:
                    if (_isOpenLog) NSLog(@"当前无网络");
                    networkStatusBlock ? networkStatusBlock(BRNetworkStatusNotReachable) : nil;
                    break;
                case AFNetworkReachabilityStatusReachableViaWWAN:
                    if (_isOpenLog) NSLog(@"当前是蜂窝网络");
                    networkStatusBlock ? networkStatusBlock(BRNetworkStatusReachableViaWWAN) : nil;
                    break;
                case AFNetworkReachabilityStatusReachableViaWiFi:
                    if (_isOpenLog) NSLog(@"当前是wifi环境");
                    networkStatusBlock ? networkStatusBlock(BRNetworkStatusReachableViaWiFi) : nil;
                    break;
                default:
                    break;
            }
        }];
    });
}

#pragma mark - 是否打开网络加载菊花(默认打开)
+ (void)openNetworkActivityIndicator:(BOOL)open {
    // 当使用AF发送网络请求时,只要有网络操作,那么在状态栏(电池条)wifi符号旁边显示  菊花提示
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:open];
}

#pragma mark - 判断当前是否有网络连接
+ (BOOL)isNetwork {
    return [AFNetworkReachabilityManager sharedManager].reachable;
}

#pragma mark - 判断当前是否是手机网络
+ (BOOL)isWWANNetwork {
    return [AFNetworkReachabilityManager sharedManager].reachableViaWWAN;
}

#pragma mark - 判断当前是否是WIFI网络
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
        // 一定要加这个判断，防止格式不对而崩溃
        if ([NSJSONSerialization isValidJSONObject:self]) {
            // 字典转Json字符串
            NSError *error = nil;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:NSJSONWritingPrettyPrinted error:&error];
            logString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
    } @catch (NSException *exception) {
        logString = [NSString stringWithFormat:@"reason: %@ \n%@", exception.reason, self.description];
    } @finally {
        
    }
    return logString;
}

@end
#endif
