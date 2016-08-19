//
//  YTURLProtocol.m
//  WebviewCache
//
//  Created by xidee on 16/3/31.
//  Copyright © 2016年 xidee All rights reserved.
//

#import "YTURLProtocol.h"
#import <UIKit/UIImage.h>
#import <MobileCoreServices/UTType.h>
#define HOST @"h5.yintai.com"
#define H5ResourcePath [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"H5Resource"]

@interface YTURLProtocol ()<NSURLSessionDelegate>

@property (nonatomic ,strong) NSURLSession *session;

@end

@implementation YTURLProtocol
//这个方法用来返回是否需要处理这个请求，如果需要处理，返回YES，否则返回NO。在该方法中可以对不需要处理的请求进行过滤。
+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    //已请求过
    if ([NSURLProtocol propertyForKey:@"protocolKey" inRequest:request]) {
        return NO;
    }
    return [request.URL.host isEqualToString:HOST];
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

//重写该方法，需要在该方法中发起一个请求,就是发起一个NSURLSessionTask
- (void)startLoading
{
    //取host 和 path 拼目录
    NSString *prefix = [self.request.URL.host stringByAppendingPathComponent:self.request.URL.path];
    //从应用沙盒当中取
    NSString* path = [H5ResourcePath stringByAppendingPathComponent:prefix];
    NSData * data = [NSData dataWithContentsOfFile:path];
    
    
    if (!data) {
        //证明本地没有该文件 这时候执行下载
        //标记这个request已经请求过 否则会一直重复请求
        NSMutableURLRequest * request = [self.request mutableCopy];
        [NSURLProtocol setProperty:@(YES) forKey:@"protocolKey" inRequest:request];
        NSURLSessionConfiguration * config = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        NSURLSessionDataTask * task = [self.session dataTaskWithRequest:request];
        [task resume];
    }else
    {   //本地有数据直接作为结果返回给客户端
        NSURLResponse *response = [[NSURLResponse alloc] initWithURL:self.request.URL MIMEType:[self getFileMIMETypeWithURL:path] expectedContentLength:[data length] textEncodingName:nil];
        [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        [[self client] URLProtocol:self didLoadData:data];
        [[self client] URLProtocolDidFinishLoading:self];
    }
}

- (void)stopLoading
{
    [self.session invalidateAndCancel];
    self.session = nil;
}

#pragma mark - NSURLSessionDataDelegate

-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (error) {
        [self.client URLProtocol:self didFailWithError:error];
    } else {
        [self.client URLProtocolDidFinishLoading:self];
    }
}

-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    completionHandler(NSURLSessionResponseAllow);
}

-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    [self.client URLProtocol:self didLoadData:data];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
 willCacheResponse:(NSCachedURLResponse *)proposedResponse
 completionHandler:(void (^)(NSCachedURLResponse *cachedResponse))completionHandler
{
    completionHandler(proposedResponse);
}
//通过这个方法跳过ssl证书验证
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * __nullable credential))completionHandler
{
    //当challenge 为证书信任时
    if (challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust) {
        //告诉服务端信任证书
        NSURLCredential *credntial = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential,credntial);
    }
}

#pragma mark - tool methed

/*
 *  @return 根据本地文件获取文件的MIMEType C的方法
 */
- (NSString *)getFileMIMETypeWithURL :(NSString *)path
{
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)[path pathExtension], NULL);
    CFStringRef MIMEType = UTTypeCopyPreferredTagWithClass (UTI, kUTTagClassMIMEType);
    CFRelease(UTI);
    if (!MIMEType) {
        return @"application/octet-stream";
    }
    return (__bridge NSString *)(MIMEType);
}

@end
