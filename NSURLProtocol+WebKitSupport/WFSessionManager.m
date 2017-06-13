//
//  WFSessionManager.m
//  WenFang
//
//  Created by sam.hu on 2017/6/6.
//  Copyright © 2017年 maili. All rights reserved.
//

#import "WFSessionManager.h"



#define  K_SESSIONID    @"JSESSIONID"


@implementation WFSessionManager




+(instancetype)instanceManager{
    
    static dispatch_once_t onceToken;
    static WFSessionManager * manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[[self class] alloc] init];
    });
    return manager;
}




-(NSString *)readCurrentCookie{
    
    NSString* sessionId = [[NSUserDefaults standardUserDefaults] valueForKey:K_SESSIONID];
    NSLog(@"cookie dictionary found is %@",sessionId);
    if (sessionId) {
        NSString *jssessionCookie = [NSString stringWithFormat:@"document.cookie = '%@=%@';", K_SESSIONID, sessionId];
        return jssessionCookie;
    }
    return nil;
}

-(void)saveSession:(NSURL *)url{
        NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL: url];
        NSLog(@"request cookies:%@",cookies);
        for (NSHTTPCookie *cookie in cookies) {
            if ([K_SESSIONID isEqualToString:cookie.name] ) {
                [[NSUserDefaults standardUserDefaults] setValue:cookie.value forKey:K_SESSIONID];
                [[NSUserDefaults standardUserDefaults] synchronize];
                break;
            }
        }
}

-(void)reset {
	
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:K_SESSIONID];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
