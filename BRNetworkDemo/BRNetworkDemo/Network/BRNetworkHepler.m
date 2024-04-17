//
//  BRNetworkHepler.m
//  BRNetworkDemo
//
//  Created by 任波 on 2018/4/28.
//  Copyright © 2018年 91renb. All rights reserved.
//

#import "BRNetworkHepler.h"
#import <BRNetwork.h>

@implementation BRNetworkHepler

+ (void)configRequest {
    [BRNetwork setIsOpenLog:YES];
    [BRNetwork setRequestTimeoutInterval:20];
    [BRNetwork setRequestSerializerType:BRRequestSerializerHTTP];
    [BRNetwork setResponseSerializerType:BRResponsetSerializerJSON];
    [BRNetwork setBaseUrl:@"https://api.xxxx.com"];
}

+ (void)getWithUrl:(NSString *)url
            params:(NSDictionary *)params
           headers:(NSDictionary *)headers
           success:(BRRequestSuccess)successBlock
           failure:(BRRequestFailure)failureBlock {
    [self configRequest];
    [BRNetwork requestWithMethod:BRRequestMethodGET url:url params:params headers:headers cachePolicy:BRCachePolicyNetworkOnly success:^(NSURLSessionDataTask * _Nullable task, id  _Nullable responseObject) {
        successBlock ? successBlock(responseObject, nil) : nil;
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failureBlock ? failureBlock(error, nil) : nil;
    }];
}

+ (void)postWithUrl:(NSString *)url
             params:(NSDictionary *)params
            headers:(NSDictionary *)headers
            success:(BRRequestSuccess)successBlock
            failure:(BRRequestFailure)failureBlock {
    [self configRequest];
    [BRNetwork requestWithMethod:BRRequestMethodPOST url:url params:params headers:headers cachePolicy:BRCachePolicyNetworkOnly success:^(NSURLSessionDataTask * _Nullable task, id  _Nullable responseObject) {
        successBlock ? successBlock(responseObject, nil) : nil;
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failureBlock ? failureBlock(error, nil) : nil;
    }];
}

@end
