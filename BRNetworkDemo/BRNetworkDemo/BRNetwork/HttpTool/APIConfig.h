//
//  APIConfig.h
//  BRNetworkDemo
//
//  Created by 任波 on 2018/4/8.
//  Copyright © 2018年 91renb. All rights reserved.
//

#ifndef APIConfig_h
#define APIConfig_h

/** 服务器地址 */
#ifdef DEBUG
/** ------------------调试状态------------------ */
//13415617890   15158135293
#define SERVER_HOST @"http://mzjksc.ibabycloud.cn"

#else
/** ------------------发布状态------------------ */
#define SERVER_HOST @"http://ibaby.junbaotech.cn"

#endif

/** 基本接口地址(服务端查看日志：biglog=1) */
#define AppBaseUrl [NSString stringWithFormat:@"%@/FSFY/disPatchJson?clazz=READDATA&sUserID=1&UITYPE=ABY/APP", SERVER_HOST]


#endif /* APIConfig_h */
