//
//  ViewController.m
//  NSURLProtocol+WebKitSupport
//
//  Created by yeatse on 2016/10/11.
//  Copyright © 2016年 Yeatse. All rights reserved.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>
#import "WFWebView.h"
#import "NSURLProtocol+WebKitSupport.h"

@interface ViewController ()<WKNavigationDelegate, UIWebViewDelegate,WKScriptMessageHandler>

@property (nonatomic) __kindof UIView* webView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self.view addSubview:self.webView];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://game.mailizc.com"]];
//    http://www.wenfangba.com?appType=isApp
    
    [(WFWebView*)self.webView loadRequest:request];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    NSSet* types = [NSSet setWithArray:@[WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache]];
    [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:types modifiedSince:[NSDate dateWithTimeIntervalSince1970:0] completionHandler:^{}];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    

    
    NSLog(@"didFinishNavigation");
}

-(void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation{
    
   
    NSLog(@"didStartProvisionalNavigation");
}



-(void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{
    NSDictionary *dict = message.body;
    NSLog(@"body:%@",dict);
    
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    self.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
}

#pragma mark - Getters

- (UIView *)webView {
    if (!_webView) {
        
        
        //1.创建配置项
        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
        config.selectionGranularity = WKSelectionGranularityDynamic;
        
        //1.1 设置偏好
        config.preferences = [[WKPreferences alloc] init];
        config.preferences.minimumFontSize = 10;
        config.preferences.javaScriptEnabled = YES;
        //1.1.1 默认是不能通过JS自动打开窗口的，必须通过用户交互才能打开
        config.preferences.javaScriptCanOpenWindowsAutomatically = NO;
        config.processPool = [[WKProcessPool alloc] init];
        
        //2.添加WKWebView
        _webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, [UIApplication sharedApplication].keyWindow.bounds.size.width, [UIApplication sharedApplication].keyWindow.bounds.size.height) configuration:config];
        _webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth ;
        
        
        
        if ([_webView respondsToSelector:@selector(setNavigationDelegate:)]) {
            [_webView setNavigationDelegate:self];
        }
        
        if ([_webView respondsToSelector:@selector(setDelegate:)]) {
            [_webView setDelegate:self];
        }
    }
    return _webView;
}


@end
