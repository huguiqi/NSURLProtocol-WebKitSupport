//
//  WFWebView.m
//  NSURLProtocol+WebKitSupport
//
//  Created by sam.hu on 2017/6/8.
//  Copyright © 2017年 Yeatse. All rights reserved.
//

#import "WFWebView.h"
#import "NSHTTPCookie+Utils.h"
#import "WFSessionManager.h"


@interface WFWebView()

@property(nonatomic,readwrite,strong) NSMutableURLRequest *currentReq;

@end

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






-(id)loadRequest:(NSURLRequest *)request{
    
    NSMutableURLRequest *req = [request mutableCopy];
    NSString *cookieValue= [[WFSessionManager instanceManager] readCurrentCookie];
    if (cookieValue) {
        //添加在js中操作的对象名称，通过该对象来向web view发送消息
        WKUserScript * cookieScript = [[WKUserScript alloc]initWithSource:cookieValue   injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
        [self.configuration.userContentController addUserScript:cookieScript];
        self.configuration.processPool = [[WKProcessPool alloc] init];
    }
    
    [req setHTTPShouldHandleCookies:NO];
    
    self.currentReq = req;
    return [super loadRequest:req];
}



@end
