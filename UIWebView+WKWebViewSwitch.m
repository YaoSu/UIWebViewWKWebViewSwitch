//
//  UIWebView+WKWebViewSwitch.m
//  UIWebViewExtension
//
//  Created by suyao on 6/15/16.
//  Copyright © 2016 suyao. All rights reserved.
//

#import "UIWebView+WKWebViewSwitch.h"
#import <objc/runtime.h>
@import WebKit;
@implementation UIWebView (WKWebViewSwitch)


+ (instancetype)alloc{
    Class wkWebView = NSClassFromString(@"WKWebView");
    if (wkWebView){
        return [wkWebView alloc];
    }else
    {
        return [super alloc];
    }
}

@end
