//
//  ReplacingImageURLProtocol.m
//  NSURLProtocol+WebKitSupport
//
//  Created by yeatse on 2016/10/11.
//  Copyright © 2016年 Yeatse. All rights reserved.
//

#import "ReplacingImageURLProtocol.h"

#import <UIKit/UIKit.h>

#import "NSString+JSON.h"

static NSString* const FilteredKey = @"FilteredKey";

@interface ReplacingImageURLProtocol()<NSURLSessionTaskDelegate,NSURLSessionDataDelegate>

@property(nonatomic,strong) NSURLSession *session;
@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic, strong) NSURLSessionDataTask *task;

@end

@implementation ReplacingImageURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    //处理过不再处理
    if ([NSURLProtocol propertyForKey:FilteredKey inRequest:request]) {
        return NO;
    }
    return YES;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b
{
    return [super requestIsCacheEquivalent:a toRequest:b];
}


- (void)startLoading
{
    NSMutableURLRequest *mutableReqeust = [[self request] mutableCopy];
    
    NSString *requestBody = [self.request valueForHTTPHeaderField:@"Request-Post-Body"];
    if (requestBody) {
        NSData * data = [[self doReqBodyStr:requestBody] dataUsingEncoding:NSUTF8StringEncoding];
        [mutableReqeust setHTTPBody:data];
    }
    
    //标记，已经处理过
    [NSURLProtocol setProperty:@(YES) forKey:FilteredKey inRequest:mutableReqeust];
    
//    self.connection = [NSURLConnection connectionWithRequest:mutableReqeust delegate:self];
    
    
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        // 实例化网络会话
        self.session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    self.task = [self.session dataTaskWithRequest:mutableReqeust];
        // 创建请求Task
//        self.task = [self.session dataTaskWithURL:self.request.URL];
//        // 开启网络任务
        [self.task resume];
    
}


-(NSString *)doReqBodyStr:(NSString *)jsonStr{
    NSDictionary *bodyDict = [jsonStr dictionaryWithJsonString];
    
    NSMutableArray *array = @[].mutableCopy;
    [bodyDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [array addObject:[NSString stringWithFormat:@"%@=%@", key, obj]];
    }];
    return [array componentsJoinedByString:@"&"];
}


- (void)stopLoading {
    
    [self.task cancel];
}


- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error{
    if (error) {
        [self.client URLProtocol:self didFailWithError:error];
    }else{
        [self.client URLProtocolDidFinishLoading:self];
    }
}


- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler{

    self.responseData = [[NSMutableData alloc] init];
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    completionHandler(NSURLSessionResponseAllow);
}


- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data{

    [self.responseData appendData:data];
    [self.client URLProtocol:self didLoadData:data];
    
    
}






@end
