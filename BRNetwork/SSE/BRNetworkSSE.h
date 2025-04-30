//
//  BRNetworkSSE.h
//  BRNetworkDemo
//
//  Created by renbo on 2025/3/21.
//  Copyright © 2018年 irenb. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^BROnMessageBlock)(NSString * _Nullable event, id _Nullable data);
typedef void(^BROnCompleteBlock)(void);
typedef void(^BROnErrorBlock)(NSError * _Nonnull error);

NS_ASSUME_NONNULL_BEGIN

@interface BRNetworkSSE : NSObject
/** 请求地址 */
@property (nonatomic, copy) NSString *url;
/** 请求方法（GET/POST） */
@property (nonatomic, copy) NSString *method;
/** 请求头 */
@property (nullable, nonatomic, copy) NSDictionary *headers;
/** 请求参数（一般为字典类型）*/
@property (nullable, nonatomic, strong) id params;
/** 设置请求超时时间(默认20秒) */
@property (nonatomic, assign) NSTimeInterval timeoutInterval;
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

NS_ASSUME_NONNULL_END
