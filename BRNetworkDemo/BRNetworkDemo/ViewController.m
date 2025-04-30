//
//  ViewController.m
//  BRNetworkDemo
//
//  Created by renbo on 2018/4/8.
//  Copyright © 2018年 irenb. All rights reserved.
//

#import "ViewController.h"
#import <BRNetworkSSE.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self startSSERequest];
}

#pragma mark - 快速发起 SSE 请求（基于 阿里云百炼平台 示例）
- (void)startSSERequest {
    NSString *url = @"https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions";
    // 1. 构造请求参数
    NSDictionary *params = @{
        @"model": @"qwen-plus",
        @"messages": @[
            @{
                @"role": @"user",
                @"content": @"你是谁？"
            }
        ],
        @"stream": @YES
    };
    // 2. 构造请求头
    NSDictionary *headers = @{
        @"Authorization": @"Bearer sk-exxxxx",
        @"Content-Type": @"application/json",
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
