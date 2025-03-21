//
//  BRNetworkSSE.h
//  BRNetworkDemo
//
//  Created by renbo on 2018/4/27.
//  Copyright © 2018年 irenb. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^BROnMessageBlock)(NSString *event, id data);
typedef void(^BROnErrorBlock)(NSError *error);

@interface BRFetchEventSource : NSObject
@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *method;
@property (nonatomic, copy) NSDictionary *headers;
@property (nonatomic, copy) NSDictionary *body;
@property (nonatomic, copy) BROnMessageBlock onMessageBlock;
@property (nonatomic, copy) BROnErrorBlock onErrorBlock;

- (void)startListening;
- (void)stopListening;

@end

@interface BRNetworkSSE : NSObject


+ (void)getWithUrl:(NSString *)url
            params:(nullable NSDictionary *)params
           headers:(nullable NSDictionary *)headers
    onMessageBlock:(nullable BROnMessageBlock)onMessageBlock
      onErrorBlock:(nullable BROnErrorBlock)onErrorBlock;


+ (void)postWithUrl:(NSString *)url
             params:(nullable NSDictionary *)params
            headers:(nullable NSDictionary *)headers
     onMessageBlock:(nullable BROnMessageBlock)onMessageBlock
       onErrorBlock:(nullable BROnErrorBlock)onErrorBlock;

@end


NS_ASSUME_NONNULL_END
