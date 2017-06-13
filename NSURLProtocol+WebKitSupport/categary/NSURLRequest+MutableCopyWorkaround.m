//
//  NSURLRequest+MutableCopyWorkaround.m
//  ProvidentFund
//
//  Created by 9188 on 2016/12/12.
//  Copyright © 2016年 9188. All rights reserved.
//

#import "NSURLRequest+MutableCopyWorkaround.h"
#import "NSString+JSON.h"

@implementation NSURLRequest (MutableCopyWorkaround)
- (id) mutableCopyWorkaround {
    NSMutableURLRequest *mutableURLRequest = [[NSMutableURLRequest alloc] initWithURL:[self URL]
                                                                          cachePolicy:[self cachePolicy]
                                                                      timeoutInterval:[self timeoutInterval]];
    [mutableURLRequest setAllHTTPHeaderFields:[self allHTTPHeaderFields]];
    
    NSString *requestBody = [self valueForHTTPHeaderField:@"Request-Post-Body"];
    if (requestBody) {
        NSData * data = [[self doReqBodyStr:requestBody] dataUsingEncoding:NSUTF8StringEncoding];
        [mutableURLRequest setHTTPBody:data];
    }
    [mutableURLRequest setHTTPMethod:[self HTTPMethod]];

    
    return mutableURLRequest;
}



-(NSString *)doReqBodyStr:(NSString *)jsonStr{
    NSDictionary *bodyDict = [jsonStr dictionaryWithJsonString];
    
    NSMutableArray *array = @[].mutableCopy;
    [bodyDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [array addObject:[NSString stringWithFormat:@"%@=%@", key, obj]];
    }];
    return [array componentsJoinedByString:@"&"];
}

@end
