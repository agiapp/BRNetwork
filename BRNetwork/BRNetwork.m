//
//  BRNetwork.m
//  BRNetworkDemo
//
//  Created by renbo on 2018/4/27.
//  Copyright © 2018年 irenb. All rights reserved.
//

#import "BRNetwork.h"
#if __has_include(<AFNetworking/AFNetworking.h>)
#import <AFNetworking/AFNetworking.h>
#else
#import "AFNetworking.h"
#endif
// 电池条上网络活动提示(菊花转动)
#import "AFNetworkActivityIndicatorManager.h"

#ifdef __OBJC__

// 日志输出宏定义
#define BRApiLog(FORMAT, ...) fprintf(stderr, "%s:[第%d行]\t%s\n", [[[NSString stringWithUTF8String: __FILE__] lastPathComponent] UTF8String], __LINE__, [[NSString stringWithFormat: FORMAT, ## __VA_ARGS__] UTF8String]);

#endif

@implementation BRNetwork

// 以下变量是公共配置，不支持二次修改
static NSString *_baseUrl;
static NSDictionary *_baseParameters;   // 公共参数
static NSDictionary *_encodeParameters; // 加密参数
static BOOL _isOpenLog;    // 是否开启日志打印
static BOOL _isNeedEncry;  // 是否需要加密传输
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
    // 设置默认数据
    [self configDefaultData];
}

#pragma mark - 设置默认值
+ (void)configDefaultData {
    // 设置请求参数的格式：二进制格式（默认为：AFHTTPRequestSerializer 二进制格式）
    _sessionManager.requestSerializer = [AFHTTPRequestSerializer serializer];
    // 设置服务器返回结果的格式：二进制格式（默认为：AFJSONResponseSerializer JSON格式）
    _sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
    // 配置响应序列化(设置请求接口回来的时候支持什么类型的数据,设置接收参数类型)
    _sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json",
                                                                 @"text/html",
                                                                 @"text/json",
                                                                 @"text/plain",
                                                                 @"multipart/form-data",
                                                                 @"text/javascript",
                                                                 @"text/xml",
                                                                 @"image/*",
                                                                 @"application/octet-stream",
                                                                 @"application/zip",
                                                                 @"text/text", nil];
    // 最大请求并发任务数
    //_sessionManager.operationQueue.maxConcurrentOperationCount = 5;
    // 设置请求超时时间
    _sessionManager.requestSerializer.timeoutInterval = 30;
    // 打开状态栏菊花
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    // 默认关闭日志
    _isOpenLog = NO;
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
//+ (void)setRequestHeaderFieldValueDictionary:(NSDictionary *)dic {
//    if (dic && dic.count > 0) {
//        for (NSString *key in dic.allKeys) {
//            [_sessionManager.requestSerializer setValue:dic[key] forHTTPHeaderField:key];
//        }
//    }
//}

#pragma mark - 设置请求超时时间(默认30s)
+ (void)setRequestTimeoutInterval:(NSTimeInterval)timeout {
    if (!_sessionManager) return;
    
    _sessionManager.requestSerializer.timeoutInterval = timeout;
}

#pragma mark - 设置请求序列化类型
+ (void)setRequestSerializerType:(BRRequestSerializer)type {
    if (!_sessionManager) return;
    
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
    if (!_sessionManager) return;
    
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

#pragma mark - GET请求方法
+ (void)getWithUrl:(NSString *)url
            params:(nullable id)params
           headers:(nullable NSDictionary *)headers
           success:(nullable BRHttpSuccessBlock)successBlock
           failure:(nullable BRHttpFailureBlock)failureBlock {
    [self requestWithMethod:BRRequestMethodGET url:url params:params headers:headers success:successBlock failure:failureBlock];
}

#pragma mark - POST请求方法
+ (void)postWithUrl:(NSString *)url
             params:(nullable id)params
            headers:(nullable NSDictionary *)headers
            success:(nullable BRHttpSuccessBlock)successBlock
            failure:(nullable BRHttpFailureBlock)failureBlock {
    [self requestWithMethod:BRRequestMethodPOST url:url params:params headers:headers success:successBlock failure:failureBlock];
}

#pragma mark - 网络请求公共方法
+ (void)requestWithMethod:(BRRequestMethod)method
                      url:(NSString *)url
                   params:(nullable id)params
                  headers:(nullable NSDictionary *)headers
                  success:(nullable BRHttpSuccessBlock)successBlock
                  failure:(nullable BRHttpFailureBlock)failureBlock {
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
    
    [self dataTaskWithMethod:method url:url params:params headers:headers success:^(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject) {
        
        BOOL isEmpty = (responseObject == nil || [responseObject isEqual:[NSNull null]] ||
        [responseObject isEqual:@"null"] || [responseObject isEqual:@"(null)"] ||
        ([responseObject respondsToSelector:@selector(length)] && [(NSData *)responseObject length] == 0) ||
        ([responseObject respondsToSelector:@selector(count)] && [(NSArray *)responseObject count] == 0));
    
        // 响应序列化类型是HTTP时，请求结果输出的是二进制数据
        if (!isEmpty && ![NSJSONSerialization isValidJSONObject:responseObject]) {
            NSError *error = nil;
            // 将二进制数据序列化成JSON数据
            id obj = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:&error];
            if (error) {
                if (_isOpenLog) BRApiLog(@"二进制数据序列化成JSON数据失败：%@", error);
            } else {
                responseObject = obj;
            }
        }
        if (_isOpenLog) BRApiLog(@"\nurl：%@\nheader：\n%@\nparams：\n%@\nsuccess：\n%@\n\n", url, headers, params, responseObject);
        [[self allSessionTask] removeObject:task];
        successBlock ? successBlock(task, responseObject) : nil;
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (_isOpenLog) BRApiLog(@"\nurl：%@\nheader：\n%@\nparams：\n%@\nfailure：\n%@\n\n", url, headers, params, error);
        failureBlock ? failureBlock(task, error) : nil;
        [[self allSessionTask] removeObject:task];
    }];
}

#pragma mark - 请求任务
+ (void)dataTaskWithMethod:(BRRequestMethod)method
                       url:(NSString *)url
                    params:(nullable id)params
                   headers:(nullable NSDictionary <NSString *, NSString *> *)headers
                   success:(nullable void (^)(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject))success
                   failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error))failure {
    NSURLSessionTask *sessionTask = nil;
    if (method == BRRequestMethodGET) {
        sessionTask = [_sessionManager GET:url parameters:params headers:headers progress:nil success:success failure:failure];
    } else if (method == BRRequestMethodPOST) {
        sessionTask = [_sessionManager POST:url parameters:params headers:headers progress:nil success:success failure:failure];
    } else if (method == BRRequestMethodHEAD) {
        sessionTask = [_sessionManager HEAD:url parameters:params headers:headers success:nil failure:failure];
    } else if (method == BRRequestMethodPUT) {
        sessionTask = [_sessionManager PUT:url parameters:params headers:headers success:success failure:failure];
    } else if (method == BRRequestMethodPATCH) {
        sessionTask = [_sessionManager PATCH:url parameters:params headers:headers success:success failure:failure];
    } else if (method == BRRequestMethodDELETE) {
        sessionTask = [_sessionManager DELETE:url parameters:params headers:headers success:success failure:failure];
    } else {
        sessionTask = [_sessionManager GET:url parameters:params headers:headers progress:nil success:success failure:failure];
    }
    
    //添加最新的sessionTask到数组
    sessionTask ? [[self allSessionTask] addObject:sessionTask] : nil;
}

#pragma mark - 下载文件
+ (void)downloadFileWithUrl:(NSString *)url
                  cachePath:(NSString *)cachePath
                   progress:(nullable void(^)(NSProgress *progress))progressBlock
                    success:(nullable void(^)(NSString *filePath))successBlock
                    failure:(nullable void(^)(NSError *error))failureBlock {
    NSURL *URL = [NSURL URLWithString:url];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    __block NSURLSessionDownloadTask *downloadTask = [_sessionManager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        // 下载进度
        // progress.completedUnitCount: 当前大小;
        // Progress.totalUnitCount: 总大小
        if (_isOpenLog) BRApiLog(@"下载进度：%.2f%%",100.0 * downloadProgress.completedUnitCount / downloadProgress.totalUnitCount);
        progressBlock ? progressBlock(downloadProgress) : nil;
    } destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        // 下载完后，实际下载在临时文件夹里；在这里需要把文件保存到本地沙盒 cachePath 目录下
        // 1.打开文件管理器
        NSFileManager *fileManager = [NSFileManager defaultManager];
        // 2.创建Download目录
        [fileManager createDirectoryAtPath:cachePath withIntermediateDirectories:YES attributes:nil error:nil];
        // 3.拼接文件路径
        NSString *filePath = [cachePath stringByAppendingPathComponent:response.suggestedFilename];
        // 4.返回文件位置的URL路径
        return [NSURL fileURLWithPath:filePath];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        [[self allSessionTask] removeObject:downloadTask];
        if (!error) {
            // NSURL 转 NSString: filePath.path 或 filePath.absoluteString
            successBlock ? successBlock(filePath.path) : nil;
        } else {
            failureBlock ? failureBlock(error) : nil;
        }
    }];
    // 开始下载
    [downloadTask resume];
    // 添加sessionTask到数组
    downloadTask ? [[self allSessionTask] addObject:downloadTask] : nil;
}

#pragma mark - 上传文件（传入的是：文件二进制数据）
+ (void)uploadFileWithUrl:(NSString *)url
                   params:(nullable id)params
                  headers:(nullable NSDictionary *)headers
                 fileData:(NSData *)fileData
                     name:(NSString *)name
                 fileName:(NSString *)fileName
                 mimeType:(NSString *)mimeType
                 progress:(nullable void(^)(NSProgress *progress))progressBlock
                  success:(nullable BRHttpSuccessBlock)successBlock
                  failure:(nullable BRHttpFailureBlock)failureBlock {
    [self uploadTaskWithUrl:url params:params headers:headers constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        // 在这个block中设置需要上传的文件
    
        /**
          这个方法的作用是将指定的文件添加到表单数据中，以便在发送 HTTP 请求时一起发送给服务器。
            data：要上传的文件[二进制流]
            name：文件流数据对应的参数名称（如：file，upload等)
            fileName：要保存在服务器上的文件名（自定义文件原名称）
            mimeType：上传的文件的类型
         */
        [formData appendPartWithFileData:fileData name:name fileName:fileName mimeType:mimeType];
    } progress:progressBlock success:successBlock failure:failureBlock];
}

#pragma mark - 上传多个文件（传入的是：文件二进制数据）
+ (void)uploadFilesWithUrl:(NSString *)url
                    params:(nullable id)params
                   headers:(nullable NSDictionary *)headers
                 fileDatas:(NSArray<NSData *> *)fileDatas
                      name:(NSString *)name
                  fileName:(NSString *)fileName
                  mimeType:(NSString *)mimeType
                  progress:(nullable void(^)(NSProgress *progress))progressBlock
                   success:(nullable BRHttpSuccessBlock)successBlock
                   failure:(nullable BRHttpFailureBlock)failureBlock {
    [self uploadTaskWithUrl:url params:params headers:headers constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        // 在这个block中设置需要上传的文件
        // 使用循环同时上传多个文件
        [fileDatas enumerateObjectsUsingBlock:^(NSData * _Nonnull fileData, NSUInteger idx, BOOL * _Nonnull stop) {
            // 这个方法的作用是将指定的文件添加到表单数据中，以便在发送 HTTP 请求时一起发送给服务器。
            [formData appendPartWithFileData:fileData name:name fileName:fileName mimeType:mimeType];
        }];
    } progress:progressBlock success:successBlock failure:failureBlock];
}

#pragma mark - 上传文件（传入的是：本地文件路径，按文件原名称上传到服务器）
+ (void)uploadFileWithUrl:(NSString *)url
                   params:(nullable id)params
                  headers:(nullable NSDictionary *)headers
                 filePath:(NSString *)filePath
                     name:(NSString *)name
                 progress:(nullable void(^)(NSProgress *progress))progressBlock
                  success:(nullable BRHttpSuccessBlock)successBlock
                  failure:(nullable BRHttpFailureBlock)failureBlock {
    [self uploadTaskWithUrl:url params:params headers:headers constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        // 在这个block中设置需要上传的文件
        NSError *error = nil;
        // 按文件原名称上传到服务器
        // 此方法省略了参数 fileName 和 mimeType，会根据'fileURL'的最后一个路径组件和'fileURL'扩展的系统关联MIME类型自动生成。
        [formData appendPartWithFileURL:[NSURL URLWithString:filePath] name:name error:&error];
        if (error) {
            NSLog(@"error=%@", error);
        }
    } progress:progressBlock success:successBlock failure:failureBlock];
}

#pragma mark - 上传图片
+ (void)uploadImageWithUrl:(NSString *)url
                    params:(nullable id)params
                   headers:(nullable NSDictionary *)headers
                     image:(UIImage *)image
                      name:(NSString *)name
                  progress:(nullable void(^)(NSProgress *progress))progressBlock
                   success:(nullable BRHttpSuccessBlock)successBlock
                   failure:(nullable BRHttpFailureBlock)failureBlock {
    [self uploadTaskWithUrl:url params:params headers:headers constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        // 在这个block中设置需要上传的文件
        
        // 将UIImage转换为JPEG格式的NSData（这里的1.0是质量参数）
        NSData *imageData = UIImageJPEGRepresentation(image, 1.0f);
        
        // 自定义上传的图片名称
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyyMMddHHmmss";
        NSString *timeStr = [formatter stringFromDate:[NSDate date]];
        NSString *imageName = [NSString stringWithFormat:@"pic_%@.jpg", timeStr];
        
        [formData appendPartWithFileData:imageData name:name fileName:imageName mimeType:@"image/jpg"];
    } progress:progressBlock success:successBlock failure:failureBlock];
}

#pragma mark - 上传多个图片
+ (void)uploadImagesWithUrl:(NSString *)url
                    params:(nullable id)params
                   headers:(nullable NSDictionary *)headers
                    images:(NSArray<UIImage *> *)images
                      name:(NSString *)name
                   progress:(nullable void(^)(NSProgress *progress))progressBlock
                    success:(nullable BRHttpSuccessBlock)successBlock
                    failure:(nullable BRHttpFailureBlock)failureBlock {
    [self uploadTaskWithUrl:url params:params headers:headers constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        // 在这个block中设置需要上传的文件
        // 使用循环同时上传多个文件
        [images enumerateObjectsUsingBlock:^(UIImage * _Nonnull image, NSUInteger idx, BOOL * _Nonnull stop) {
            // 将UIImage转换为JPEG格式的NSData（这里的1.0是质量参数）
            NSData *imageData = UIImageJPEGRepresentation(image, 1.0f);
        
            // 自定义上传的图片名称
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyyMMddHHmmss";
            NSString *timeStr = [formatter stringFromDate:[NSDate date]];
            NSString *imageName = [NSString stringWithFormat:@"pic_%@%@.jpg", timeStr, @(idx)];
            
            [formData appendPartWithFileData:imageData name:name fileName:imageName mimeType:@"image/jpg"];
        }];
    } progress:progressBlock success:successBlock failure:failureBlock];
}

#pragma mark - 上传任务
+ (void)uploadTaskWithUrl:(NSString *)url
                   params:(nullable id)params
                  headers:(nullable NSDictionary *)headers
constructingBodyWithBlock:(nullable void (^)(id <AFMultipartFormData> formData))block
                 progress:(nullable void(^)(NSProgress *progress))progressBlock
                  success:(nullable BRHttpSuccessBlock)successBlock
                  failure:(nullable BRHttpFailureBlock)failureBlock {
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
    // a multipart `POST` request
    // constructingBodyWithBlock 参数说明：一个带有一个参数的块，用于向 HTTP Body 附加数据。该块参数是采用AFMultipartFormData协议的对象。
    NSURLSessionTask *sessionTask = [_sessionManager POST:url parameters:params headers:headers constructingBodyWithBlock:block progress:^(NSProgress * _Nonnull uploadProgress) {
        //上传进度
        progressBlock ? progressBlock(uploadProgress) : nil;
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        BOOL isEmpty = (responseObject == nil || [responseObject isEqual:[NSNull null]] ||
        [responseObject isEqual:@"null"] || [responseObject isEqual:@"(null)"] ||
        ([responseObject respondsToSelector:@selector(length)] && [(NSData *)responseObject length] == 0) ||
        ([responseObject respondsToSelector:@selector(count)] && [(NSArray *)responseObject count] == 0));
    
        // 响应序列化类型是HTTP时，请求结果输出的是二进制数据
        if (!isEmpty && ![NSJSONSerialization isValidJSONObject:responseObject]) {
            NSError *error = nil;
            // 将二进制数据序列化成JSON数据
            id obj = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:&error];
            if (error) {
                if (_isOpenLog) BRApiLog(@"二进制数据序列化成JSON数据失败：%@", error);
            } else {
                responseObject = obj;
            }
        }
        if (_isOpenLog) BRApiLog(@"\nurl：%@\nheader：\n%@\nparams：\n%@\nsuccess：\n%@\n\n", url, headers, params, responseObject);
        [[self allSessionTask] removeObject:task];
        successBlock ? successBlock(task, responseObject) : nil;
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (_isOpenLog) BRApiLog(@"\nurl：%@\nheader：\n%@\nparams：\n%@\nfailure：\n%@\n\n", url, headers, params, error);
        failureBlock ? failureBlock(task, error) : nil;
        [[self allSessionTask] removeObject:task];
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
                    if (_isOpenLog) BRApiLog(@"当前网络未知");
                    networkStatusBlock ? networkStatusBlock(BRNetworkStatusUnknown) : nil;
                    break;
                case AFNetworkReachabilityStatusNotReachable:
                    if (_isOpenLog) BRApiLog(@"当前无网络");
                    networkStatusBlock ? networkStatusBlock(BRNetworkStatusNotReachable) : nil;
                    break;
                case AFNetworkReachabilityStatusReachableViaWWAN:
                    if (_isOpenLog) BRApiLog(@"当前是蜂窝网络");
                    networkStatusBlock ? networkStatusBlock(BRNetworkStatusReachableViaWWAN) : nil;
                    break;
                case AFNetworkReachabilityStatusReachableViaWiFi:
                    if (_isOpenLog) BRApiLog(@"当前是wifi环境");
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

