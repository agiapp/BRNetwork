# BRNetwork
BRNetwork 是一个iOS轻量级网络请求库，封装了网络请求、本地数据缓存与SSE流式通信。

- BRNetwork：是一个基于AFNetworking封装的轻量级网络请求工具；

- BRNetworkYY：是基于BRNetwork并二次封装YYCache，整合了数据缓存功能；

- BRNetworkSSE：是一个基于SSE(Server-Sent Events)协议封装的网络请求类，专为AI大模型的流式数据响应设计，支持实时接收模型返回的数据流。

# 安装

#### CocoaPods

1. 在 Podfile 中添加 `pod 'BRNetwork'`
2. 执行 `pod install` 或 `pod update`
3. 导入头文件 ` #import <BRNetwork.h>`

> 安装说明，默认是集成全部功能，也可以选择性集成：
>
> ① 使用基础网络请求：`pod 'BRNetwork/Core'`
>
> ② 使用基础网络请求+数据缓存：`pod 'BRNetwork/YY'`
>
> ③ 使用AI大模型SSE流式请求：`pod 'BRNetwork/SSE'`

#### 手动导入

1. 将与 `README.md` 同级目录下的 BRNetwork 文件夹拽入项目中
2. 导入头文件 ` #import "BRNetwork.h"`。

# 系统要求

- iOS 9.0+
- ARC

# 使用

**1. BRNetwork：基础网络请求**

```objective-c
@interface BRNetwork : NSObject

/** 设置接口根路径 */
+ (void)setBaseUrl:(nullable NSString *)baseUrl;
/** 获取接口根路径 */
+ (nullable NSString *)baseUrl;

/** 设置接口基本参数/公共参数(如:用户ID, Token) */
+ (void)setBaseParameters:(nullable NSDictionary *)params;
/** 获取接口基本参数/公共参数(如:用户ID, Token) */
+ (nullable NSDictionary *)baseParameters;

/** 加密接口参数/加密Body */
+ (void)setEncodeParameters:(nullable NSDictionary *)params;
/** 获取加密接口参数/加密Body */
+ (nullable NSDictionary *)encodeParameters;

/** 是否开启日志打印 */
+ (void)setIsOpenLog:(BOOL)isOpenLog;
/** 获取是否开启日志打印 */
+ (BOOL)isOpenLog;

/** 是否需要加密传输 */
+ (void)setIsNeedEncry:(BOOL)isNeedEncry;
/** 获取是否需要加密传输 */
+ (BOOL)isNeedEncry;

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
 *  网络请求公共方法
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
```

**2. BRNetworkYY：基础网络请求+本地数据缓存**

```objective-c
#import "BRNetwork.h"

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

NS_ASSUME_NONNULL_BEGIN

@interface BRNetworkYY : BRNetwork

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
            params:(nullable id)params
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
            params:(nullable id)params
           headers:(nullable NSDictionary *)headers
       cachePolicy:(BRCachePolicy)cachePolicy
           success:(nullable BRHttpSuccessBlock)successBlock
           failure:(nullable BRHttpFailureBlock)failureBlock;

/**
 *  网络请求公共方法（带缓存策略）
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
                   params:(nullable id)params
                  headers:(nullable NSDictionary *)headers
              cachePolicy:(BRCachePolicy)cachePolicy
                  success:(nullable BRHttpSuccessBlock)successBlock
                  failure:(nullable BRHttpFailureBlock)failureBlock;

@end
```

**3. BRNetworkSSE：请求AI大模型流式数据**

```objective-c
typedef void(^BROnMessageBlock)(NSString * _Nullable event, id _Nullable data);
typedef void(^BROnCompleteBlock)(void);
typedef void(^BROnErrorBlock)(NSError * _Nonnull error);

@interface BRNetworkSSE : NSObject
/** 请求地址 */
@property (nonatomic, copy) NSString *url;
/** 请求方法（GET/POST） */
@property (nonatomic, copy) NSString *method;
/** 请求头 */
@property (nullable, nonatomic, copy) NSDictionary *headers;
/** 请求参数（一般为字典类型）*/
@property (nullable, nonatomic, strong) id params;
/** 请求结果的回调（执行多次，回调流式数据） */
@property (nullable, nonatomic, copy) BROnMessageBlock onMessageBlock;
/** 请求完成的回调 */
@property (nullable, nonatomic, copy) BROnCompleteBlock onCompleteBlock;
/** 请求失败的回调 */
@property (nullable, nonatomic, copy) BROnErrorBlock onErrorBlock;

/** 开始请求 */
- (void)startRequest;
/** 取消请求 */
- (void)cancelRequest;

@end
```

- 使用示例

```objective-c
#pragma mark - 快速发起 SSE 请求（基于 阿里云百炼平台 示例）
- (void)startSSERequest {
    NSString *url = @"https://dashscope.aliyuncs.com/api/v1/apps/0e4a1fd7d5dasdsadbbc94af41e18b7d7e/completion";
    // 1. 构造请求参数
    NSDictionary *params = @{
        @"input": @{
               @"prompt": @"你是谁？"
           }
    };
    // 2. 构造请求头
    NSDictionary *headers = @{
        @"Authorization": @"Bearer sk-xxxxxxx",
        @"Content-Type": @"application/json",
        @"X-DashScope-SSE": @"enable"
    };
    // 3. 创建并配置请求
    BRNetworkSSE *req = [[BRNetworkSSE alloc] init];
    req.url = url;
    req.method = @"POST";
    req.params = params;
    req.headers = headers;
    req.onMessageBlock = ^(NSString * _Nullable event, id  _Nullable data) {
        NSLog(@"收到流数据: %@", data);
    };
    req.onErrorBlock = ^(NSError * _Nonnull error) {
        NSLog(@"SSE 请求失败: %@", error.localizedDescription);
    };
    // 4. 发起请求
    [req startRequest];
}

@end
```
