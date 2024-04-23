//
//  BRBaseRequest.h
//  BRNetworkDemo
//
//  Created by renbo on 2018/4/8.
//  Copyright © 2018年 irenb. All rights reserved.
//
//  二次封装 YTKNetwork 库
//

#import "YTKRequest.h"

typedef NS_ENUM(NSInteger , BRRequestStatus) {
    /** 来自服务器定义 */
    // 正常
    BRRequestStatusSuccess                   = 200,
    // 网络失败
    BRRequestStatusFailure,
    BRRequestStatusAccessTokenExpired,
    
    BRRequestStatusLoginUserNotFound         = 404,     //令牌不存在或者 用户不存在
    BRRequestStatusLoginUserPasswordNotRight = 501,
    BRRequestStatusLoginInOtherDevice        = 615,     //账号在其他设备登录
    BRRequestStatusAccountRegisted           = 603,     //账号已经存在
    BRRequestStatusRegistedInOtherTenant     = 670,     //账号在其他租户下已经存在
    BRRequestStatusRegFailed                 = 714,     //预约挂号失败异常
    
    BRRequestStatusTokenFailure              = 409,     //令牌失效
    BRRequestStatusLoginFailure              = 503,     //设备异地登录
    BRRequestStatusEncryFailure              = 504,     //加密失败
    BRRequestStatusAppealFailure             = 502,     //账号申诉-手机号未注册
};

typedef void (^BRRequestBlock)(BRRequestStatus requestStatus, NSString *message, id responseObject);

@interface BRBaseRequest : YTKRequest

/// (封装层) 发起请求, 返回自定义对象时需要子类调用
- (void)startRequest:(BRRequestBlock)requestBlock;

/// (封装层) 解析msg, 根据statusCode解析message。因为服务器返回的是英文信息, 客户端需要转成中文
- (NSString *)formatMessage:(BRRequestStatus)statusCode;

/// (封装层) 解析数据，把服务器返回数据转换想要的数据，通常解析body内数据
- (id)formatResponseObject:(id)responseObject;

/// (封装层) HTTP头
- (NSDictionary *)requestHeaderDictionary;

@end
