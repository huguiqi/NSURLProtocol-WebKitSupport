//
//  WFWebView.m
//  NSURLProtocol+WebKitSupport
//
//  Created by sam.hu on 2017/6/8.
//  Copyright © 2017年 Yeatse. All rights reserved.
//

#import "WFWebView.h"
#import "NSHTTPCookie+Utils.h"


/**
 *  这个类暂时没用到，可以忽略
 */
@implementation WFWebView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/






/*!
 *  更新webView的cookie
 */
- (void)updateWebViewCookie
{
    WKUserScript * cookieScript = [[WKUserScript alloc] initWithSource:[self cookieString] injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
    //添加Cookie
    [self.configuration.userContentController addUserScript:cookieScript];
    
    
}

- (NSString *)cookieString
{
    NSMutableString *script = [NSMutableString string];
    for (NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]) {
        // Skip cookies that will break our script
        if ([cookie.value rangeOfString:@"'"].location != NSNotFound) {
            continue;
        }
        // Create a line that appends this cookie to the web view's document's cookies
        [script appendFormat:@"document.cookie='%@'; \n", cookie.da_javascriptString];
    }
    return script;
}

@end
