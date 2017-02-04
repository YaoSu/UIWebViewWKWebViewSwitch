//
//  WKWebView+UIWebViewAdapter.h
//  UIWebViewExtension
//
//  Created by suyao on 6/15/16.
//  Copyright © 2016 suyao. All rights reserved.
//

#import <WebKit/WebKit.h>

// stringByEvaluatingJavaScriptFromString不能在 - (BOOL)webView:shouldStartLoadWithRequest:navigationType:shouldStartLoadWithRequest 中被调用
//  原因:
//      在WKWebView调用此delegate时，此delegate不返回，真正的stringByEvaluatingJavaScriptFromString的block不会被调用
@interface WKWebView (UIWebViewAdapter)<WKUIDelegate,WKNavigationDelegate>


@end
