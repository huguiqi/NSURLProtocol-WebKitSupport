//
//  NSString+JSON.h
//  NSURLProtocol+WebKitSupport
//
//  Created by sam.hu on 2017/6/9.
//  Copyright © 2017年 Yeatse. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (JSON)

- (NSDictionary *)dictionaryWithJsonString;

- (NSString*)dictionaryToJson:(NSDictionary *)dic;

@end
