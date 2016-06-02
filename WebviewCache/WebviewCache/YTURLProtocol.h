//
//  YTURLProtocol.h
//  WebviewCache
//
//  Created by xidee on 16/3/31.
//  Copyright © 2016年 xidee All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YTURLProtocol : NSURLProtocol <NSURLConnectionDataDelegate,NSURLSessionDelegate>

@property (nonatomic ,strong) NSURLConnection *connection;
@property (nonatomic ,strong) NSURLSession *session;

@end
