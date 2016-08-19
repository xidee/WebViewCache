//
//  ViewController.m
//  WebviewCache
//
//  Created by xidee on 16/3/31.
//  Copyright © 2016年 xidee All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()<UIWebViewDelegate,NSURLSessionDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *webview;
@property (nonatomic ,strong) NSURLSession *session;
@property (nonatomic ,strong) NSMutableURLRequest *request;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSURL *url = [NSURL URLWithString:@"http://www.12306.cn/mormhweb"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webview loadRequest:request];
}


@end
