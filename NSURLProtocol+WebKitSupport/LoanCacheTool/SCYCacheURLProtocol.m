//
//  SCYCacheURLProtocol.m
//  ProvidentFund
//
//  Created by 9188 on 2016/12/12.
//  Copyright © 2016年 9188. All rights reserved.
//

#import "SCYCacheURLProtocol.h"
#import "Reachability.h"
#import "NSString+CDEncryption.h"
#import "SCYWebViewCacheModel.h"
#import "NSURLRequest+MutableCopyWorkaround.h"
#import "SCYLoanHTMLCache.h"
#import "NSString+JSON.h"

static NSString *SCYCachingURLHeader = @"SCYCacheURLProtocolCache";

static NSSet *SCYCachingSupportedSchemes;

static NSString * const URLProtocolHandledKey = @"URLProtocolHandledKey";

static NSString * const CacheUrlStringKey = @"cacheUrlStringKey"; // 本地保存缓存urlKey的数组key

@interface SCYCacheURLProtocol ()<NSURLSessionTaskDelegate,NSURLSessionDataDelegate>
@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, strong) NSURLResponse *response;

@property(nonatomic,strong) NSURLSession *session;
@property (nonatomic, strong) NSURLSessionDataTask *task;

@property (nonatomic, strong) SCYWebViewCacheModel *cacheModel;

@end

@implementation SCYCacheURLProtocol
- (SCYWebViewCacheModel *)cacheModel{
    if (!_cacheModel) {
        _cacheModel = [[SCYWebViewCacheModel alloc] init];
    }
    return _cacheModel;
}

+ (void)initialize{
    if (self == [SCYCacheURLProtocol class]){
        SCYCachingSupportedSchemes = [NSSet setWithObjects:@"http", @"https", nil];
    }
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request{
    NSString* extension = request.URL.pathExtension;
    BOOL isImage = [@[@"png", @"jpeg", @"gif", @"jpg"] indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return [extension compare:obj options:NSCaseInsensitiveSearch] == NSOrderedSame;
    }] != NSNotFound;
    if (!isImage) {
        return NO;
    }
    if ([SCYCachingSupportedSchemes containsObject:[[request URL] scheme]] &&
        ([request valueForHTTPHeaderField:SCYCachingURLHeader] == nil)){
    
        //看看是否已经处理过了，防止无限循环
        if ([NSURLProtocol propertyForKey:URLProtocolHandledKey inRequest:request]) {
            return NO;
        }
        return YES;
    }
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request{
    NSMutableURLRequest *mutableReqeust = [request mutableCopy];
    return mutableReqeust;
}

/// 开始加载时自动调用
- (void)startLoading{
    //打标签，防止无限循环
    [NSURLProtocol setProperty:@YES forKey:URLProtocolHandledKey inRequest:[[self request] mutableCopy]];
    
    // 加载本地
    SCYWebViewCacheModel *cacheModel = (SCYWebViewCacheModel *)[[SCYLoanHTMLCache defaultcache] objectForKey:[[[self.request URL] absoluteString] cd_md5HexDigest]];
    
    if ([self useCache] && cacheModel == nil) { // 可到达(有网)而且无缓存  才重新获取
        [self loadRequest];
    } else if(cacheModel) { // 有缓存
        [self loadCacheData:cacheModel];
    } else { // 没网  没缓存
        NSLog(@"没网也没缓存.....");
    }
}



- (void)stopLoading {
    [self.task cancel];
}



- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler{
    if (response != nil) {
        NSMutableURLRequest *redirectableRequest = [request mutableCopyWorkaround];
        [redirectableRequest setValue:nil forHTTPHeaderField:SCYCachingURLHeader];
        
        [self cacheDataWithResponse:response redirectRequest:redirectableRequest];
        
        [[self client] URLProtocol:self wasRedirectedToRequest:redirectableRequest redirectResponse:response];
        completionHandler(redirectableRequest);
    } else {
        completionHandler(request);
    }
}



#pragma finish or error
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error{
    if (error) {
        [self.client URLProtocol:self didFailWithError:error];
    }else{
        [self.client URLProtocolDidFinishLoading:self];
        
        /// 自己项目设置的逻辑  即是服务器版本号 > 本地版本号   则需要刷新
        /// 先移除之前的缓存，在缓存新的。。对吧 这里逻辑看情况而定
        //    if ([SCYLoanUrlType() isEqualToString:@"1"] && SCYLoanSerViceVersion().integerValue > SCYLoanLocalVersion().integerValue) { // 缓存最新的时候  移除之前  loacalVersion  localUrl
        //        [[SCYLoanHTMLCache defaultcache] removeAllObjects];
        //        [[NSUserDefaults standardUserDefaults] removeObjectForKey:CacheUrlStringKey];
        //        NSLog(@"刷新网页成功.........");
        //    }
        
        ////  有缓存则不缓存
        SCYWebViewCacheModel *cacheModel = (SCYWebViewCacheModel *)[[SCYLoanHTMLCache defaultcache] objectForKey:[[[self.request URL] absoluteString] cd_md5HexDigest]];
        if (!cacheModel) {
            [self cacheDataWithResponse:self.response redirectRequest:nil];
        }
    }
}


- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler{
    
    self.data = [[NSMutableData alloc] init];
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    completionHandler(NSURLSessionResponseAllow);
}


- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data{
    
    [self.data appendData:data];
    [self.client URLProtocol:self didLoadData:data];
    
    
}



#pragma mark - private
/**
 *  存储缓存数据
 *  @param response              response
 *  @param redirectableRequest   重定向request
 */
- (void)cacheDataWithResponse:(NSURLResponse *)response  redirectRequest:(NSMutableURLRequest *)redirectableRequest{
    [self.cacheModel setResponse:response];
    [self.cacheModel setData:[self data]];
    [self.cacheModel setRedirectRequest:redirectableRequest];
    
    NSString *cacheStringkey = [[[self.request URL] absoluteString] cd_md5HexDigest];
    [[SCYLoanHTMLCache defaultcache] setObject:self.cacheModel forKey:cacheStringkey withBlock:^{
        // 注意 这里加载.css   jpg 等资源路径的时候，这个类已经更新了（即数组加urlkey数组的时候，不能在当前类一直加，而是先从本地取了之后再加）
        NSMutableArray *array = [[[NSUserDefaults standardUserDefaults] objectForKey:CacheUrlStringKey] mutableCopy];
        if (!array) {   array = @[].mutableCopy;  }
        
        [array addObject:cacheStringkey];
        [[NSUserDefaults standardUserDefaults] setObject:array forKey:CacheUrlStringKey];
        NSLog(@".....重置了缓存  key == CacheUrlStringKey....");
        NSLog(@".....新增了缓存key %@ ...., 当前缓存个数%ld",cacheStringkey, array.count);
    }];
}
/// 请求最新
- (void)loadRequest{
    NSMutableURLRequest *connectionRequest = [[self request] mutableCopyWorkaround];
    [connectionRequest setURL:self.request.URL];
    [connectionRequest setValue:@"" forHTTPHeaderField:SCYCachingURLHeader];
    
    NSString *requestBody = [self.request valueForHTTPHeaderField:@"Request-Post-Body"];
    if (requestBody) {
        NSData * data = [[self doReqBodyStr:requestBody] dataUsingEncoding:NSUTF8StringEncoding];
        [connectionRequest setHTTPBody:data];
    }
    
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    // 实例化网络会话
    self.session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    self.task = [self.session dataTaskWithRequest:connectionRequest];
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


- (BOOL)useCache{
    BOOL reachable = (BOOL) [[Reachability reachabilityWithHostName:[[[self request] URL] host]] currentReachabilityStatus] != NotReachable;
    NSLog(@"网络是否可到达  1可到达   0不可到达............. %d", reachable);
    return reachable;
}

- (void)appendData:(NSData *)newData{
    if ([self data] == nil) {
        [self setData:[newData mutableCopy]];
    } else {
        [[self data] appendData:newData];
    }
}

- (void)loadCacheData:(SCYWebViewCacheModel *)cacheModel{
    if (cacheModel) {
        NSData *data = [cacheModel data];
        NSURLResponse *response = [cacheModel response];
        NSURLRequest *redirectRequest = [cacheModel redirectRequest];
        if (response == nil) {
            return;
        }
        if (redirectRequest) {
            [[self client] URLProtocol:self wasRedirectedToRequest:redirectRequest redirectResponse:response];
            NSLog(@"redirectRequest............. 重定向");
        } else {
            [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
            [[self client] URLProtocol:self didLoadData:data];
            [[self client] URLProtocolDidFinishLoading:self];
            NSLog(@"直接使用缓存.............缓存的url == %@ ", self.request.URL.absoluteString);
        }
    } else {
        [[self client] URLProtocol:self didFailWithError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCannotConnectToHost userInfo:nil]];
    }
}
@end
