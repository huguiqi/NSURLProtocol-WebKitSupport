//
//  NSHTTPCookie+Utils.m
//  NSURLProtocol+WebKitSupport
//
//  Created by sam.hu on 2017/6/8.
//  Copyright © 2017年 Yeatse. All rights reserved.
//

#import "NSHTTPCookie+Utils.h"

@implementation NSHTTPCookie (Utils)

- (NSString *)da_javascriptString
{
    NSString *string = [NSString stringWithFormat:@"%@=%@;domain=%@;path=%@",
                        self.name,
                        self.value,
                        self.domain,
                        self.path ?: @"/"];
    if (self.secure) {
        string = [string stringByAppendingString:@";secure=true"];
    }
    return string;
}

@end
