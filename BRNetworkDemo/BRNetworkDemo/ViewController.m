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
    [self testSSE];
}

- (void)testSSE {
    NSString *url = @"https://dashscope.aliyuncs.com/api/v1/apps/0e4a1fd7d56743ebbc94af41e18b7d7e/completion";
    NSDictionary *params = @{
        @"input": @{
               @"prompt": @"你是谁？"
           }
    };
    NSDictionary *headers = @{
        @"Authorization": @"Bearer sk-xxxxxxx",
        @"Content-Type": @"application/json",
        @"X-DashScope-SSE": @"enable"
    };
    [BRNetworkSSE postWithUrl:url params:params headers:headers onMessageBlock:^(NSString * _Nonnull event, id  _Nonnull data) {
        //NSLog(@"event: %@\ndata: %@", event, data);
    } onErrorBlock:^(NSError * _Nonnull error) {
        NSLog(@"SSE 请求失败: %@", error.localizedDescription);
    }];
}

@end
