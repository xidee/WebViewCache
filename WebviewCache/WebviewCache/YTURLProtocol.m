//
//  YTURLProtocol.m
//  WebviewCache
//
//  Created by xidee on 16/3/31.
//  Copyright © 2016年 xidee All rights reserved.
//

#import "YTURLProtocol.h"
#import <UIKit/UIImage.h>

#define HOST @"10.32.150.113"

@implementation YTURLProtocol
//这个方法用来返回是否需要处理这个请求，如果需要处理，返回YES，否则返回NO。在该方法中可以对不需要处理的请求进行过滤。
+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    if ([NSURLProtocol propertyForKey:@"protocolKey" inRequest:request]) {
        return NO;
    }
    //增加host的判断 与Suffix的判断 请他请求忽略
    if ([request.URL.lastPathComponent hasSuffix:@"html"] || [request.URL.lastPathComponent hasSuffix:@"js"] || [request.URL.lastPathComponent hasSuffix:@"png"] || [request.URL.lastPathComponent hasSuffix:@"css"]) {
        if ([request.URL.host isEqualToString:HOST]) {
//            NSLog(@"截获url需求替换的请求%@",request.URL);
            return YES;
        }
        return NO;
    }else{
        return NO;
    }
}
//重写该方法，可以对请求进行修改，例如添加新的头部信息，修改，修改url等，返回修改后的请求。
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}
//该方法主要用来判断两个请求是否是同一个请求，如果是，则可以使用缓存数据，通常只需要调用父类的实现即可
+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:( NSURLRequest *)b
{
    return YES;
}
//重写该方法，需要在该方法中发起一个请求，对于NSURLConnection来说，就是创建一个NSURLConnection，对于NSURLSession，就是发起一个NSURLSessionTask
- (void)startLoading
{
    NSString *Url = [NSString stringWithFormat:@"%@",self.request.URL];
    
    //文件类型
    NSString *mimiType = @"";
    NSString *dataType = @"";
    //编码格式 不同资源类型编码方式不一 防止读写错误
    NSString *textEncodingName = @"UTF8";
    //文件名称
    NSRange range = [Url rangeOfString:@"http://10.32.150.113/"];
    NSString *dataName = [Url stringByReplacingCharactersInRange:range withString:@""];

    //取得文件类型 并且去掉后缀
    if([Url.lastPathComponent hasSuffix:@"html"])
    {
        mimiType = [NSString stringWithFormat:@"text/html"];
        dataType = @"html";
    }
    
    if([Url.lastPathComponent hasSuffix:@"js"])
    {
        mimiType=[NSString stringWithFormat:@"application/x-javascript"];
        dataType = @"js";
    }

    if([Url.lastPathComponent hasSuffix:@"png"])
    {
        mimiType=[NSString stringWithFormat:@"image/png"];
        dataType = @"png";
        textEncodingName = @"BASE64";
    }
    
    if([Url.lastPathComponent hasSuffix:@"css"])
    {
        mimiType=[NSString stringWithFormat:@"text/css"];
        dataType = @"css";
    }
    
    //拼上本地文件夹的名称
    dataName = [NSString stringWithFormat:@"/H5Resources/%@",dataName];
    NSString *cachesPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)lastObject]stringByAppendingString:dataName];
    NSData *data = [NSData dataWithContentsOfFile:cachesPath];
    if (!data) {
        //证明本地没有该文件 这时候执行下载
        NSLog(@"资源包路径不存在%@",cachesPath);
        //标记这个request已经请求过 否则会一直重复请求
        NSMutableURLRequest * request = [self.request mutableCopy];
        [NSURLProtocol setProperty:@(YES) forKey:@"protocolKey" inRequest:request];
        self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
    }else
    {   //本地有数据直接作为结果返回
        NSURLResponse *response = [[NSURLResponse alloc] initWithURL:self.request.URL MIMEType:mimiType expectedContentLength:[data length] textEncodingName:textEncodingName];
        
        [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        [[self client] URLProtocol:self didLoadData:data];
        [[self client] URLProtocolDidFinishLoading:self];
    }
}

- (void)stopLoading
{
    [self.connection cancel];
}

#pragma mark - NSURLConnectionDelegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.client URLProtocol:self didLoadData:data];
    //下载完成后缓存到本地
    //缓存路径
    NSString *Url = [NSString stringWithFormat:@"%@",self.request.URL];
    NSRange range = [Url rangeOfString:@"http://10.32.150.113/"];
    NSString *dataName = [Url stringByReplacingCharactersInRange:range withString:@""];
    //拼上本地文件夹的名称
    dataName = [NSString stringWithFormat:@"/H5Resources/%@",dataName];
    NSString *datatype = [[dataName componentsSeparatedByString:@"/"]lastObject];
    NSRange nameRange = [dataName rangeOfString:datatype];
    //文件夹路径(与url保持一致)
    NSString *datapath = [dataName stringByReplacingCharactersInRange:nameRange withString:@""];
    datapath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)lastObject]stringByAppendingString:datapath];
    //文件路径
    NSString *cachesPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)lastObject]stringByAppendingString:dataName];

    // 判断文件夹是否存在，如果不存在，则创建
    if (![[NSFileManager defaultManager] fileExistsAtPath:datapath]) {
         NSFileManager *fileManager = [[NSFileManager alloc] init];
        if([fileManager createDirectoryAtPath:datapath withIntermediateDirectories:YES attributes:nil error:nil])
        {
            if([data writeToFile:cachesPath atomically:YES])
            {
                NSLog(@"写入本地完成%@",cachesPath);
            }else
            {
                NSLog(@"写入本地失败%@",cachesPath);
            }
        }else
        {
            NSLog(@"创建文件夹失败%@",cachesPath);
        }
    }else{
        if([data writeToFile:cachesPath atomically:YES])
        {
            NSLog(@"写入本地完成%@",cachesPath);
        }else
        {
            NSLog(@"写入本地失败%@",cachesPath);
        }
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self.client URLProtocolDidFinishLoading:self];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self.client URLProtocol:self didFailWithError:error];
}

@end
