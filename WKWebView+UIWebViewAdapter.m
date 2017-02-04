//
//  WKWebView+UIWebViewAdapter.m
//  UIWebViewExtension
//
//  Created by suyao on 6/15/16.
//  Copyright © 2016 suyao. All rights reserved.
//

#import "WKWebView+UIWebViewAdapter.h"
#import <objc/runtime.h>
@implementation WKWebView (UIWebViewAdapter)

static char * WKWebViewDelegateKey;

+ (void) load
{
    Class class = [self class];
    
    SEL originalSelector = @selector(loadRequest:);
    SEL swizzledSelector = @selector(adapterLoadRequest:);
    
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    BOOL didAddMethod = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

- (id)initWithFrame:(CGRect)frame{
    
    WKWebViewConfiguration* configuration = [[NSClassFromString(@"WKWebViewConfiguration") alloc] init];
    configuration.preferences = [NSClassFromString(@"WKPreferences") new];
    configuration.userContentController = [NSClassFromString(@"WKUserContentController") new];
    self = [self initWithFrame:frame configuration:configuration];
    return self;
}

- (void)adapterLoadRequest:(NSURLRequest *)request
{
    [self setRequest:request];
    BOOL isDirectory = NO;
    
    if ([[request.URL absoluteString] hasPrefix:@"file://"]){
        BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:[request.URL relativePath] isDirectory:&isDirectory];
        if (isExist && !isDirectory) {
            [self loadFileURL:request.URL allowingReadAccessToURL:request.URL];
        }
    }else
    {
        [self adapterLoadRequest:request];
    }
}

- (NSURLRequest *)request
{
    return objc_getAssociatedObject(self, @selector(request));
}

- (void)setRequest:(NSURLRequest *)request
{
    objc_setAssociatedObject(self, @selector(request), request, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


- (void)setDelegate:(id)delegate{
    objc_setAssociatedObject(self, &WKWebViewDelegateKey, delegate, OBJC_ASSOCIATION_ASSIGN);
    self.UIDelegate = self;
    self.navigationDelegate = self;
}
- (id)delegate{
    id delegate = objc_getAssociatedObject(self, &WKWebViewDelegateKey);
    return delegate;
}
- (void)loadData:(NSData *)data MIMEType:(NSString *)MIMEType textEncodingName:(NSString *)textEncodingName baseURL:(NSURL *)baseURL{
    [self loadData:data MIMEType:MIMEType characterEncodingName:textEncodingName baseURL:baseURL];
}
- (nullable NSString *)stringByEvaluatingJavaScriptFromString:(NSString *)script{

    __block NSString *resultString = nil;
    __block BOOL finished = NO;
    [self evaluateJavaScript:script completionHandler:^(id result, NSError *error) {
        if (error == nil) {
            if (result != nil) {
                resultString = [NSString stringWithFormat:@"%@", result];
            }
        } else {
            NSLog(@"evaluateJavaScript error : %@", error.localizedDescription);
        }
        finished = YES;
    }];
    time_t ts=time(0);
    while (!finished && time(0)-ts<10)
    {
        // Runs the loop once, blocking for input in the specified mode until a given date.
      //  [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    return resultString;
}


- (void)setAllowsInlineMediaPlayback:(BOOL)allowsInlineMediaPlayback{
    WKWebViewConfiguration * configuration = self.configuration;
    configuration.allowsInlineMediaPlayback = allowsInlineMediaPlayback;
}

- (BOOL)allowsInlineMediaPlayback{
    WKWebViewConfiguration * configuration = self.configuration;
    return configuration.allowsInlineMediaPlayback;
}

- (void)setMediaPlaybackRequiresUserAction:(BOOL)mediaPlaybackRequiresUserAction{
    WKWebViewConfiguration * configuration = self.configuration;
    configuration.requiresUserActionForMediaPlayback = mediaPlaybackRequiresUserAction;
}

- (BOOL)mediaPlaybackRequiresUserAction{
    WKWebViewConfiguration * configuration = self.configuration;
    return configuration.requiresUserActionForMediaPlayback;
}

- (void)setMediaPlaybackAllowsAirPlay:(BOOL)mediaPlaybackAllowsAirPlay{
    WKWebViewConfiguration * configuration = self.configuration;
    configuration.allowsAirPlayForMediaPlayback = mediaPlaybackAllowsAirPlay;
}

- (BOOL)mediaPlaybackAllowsAirPlay{
    WKWebViewConfiguration * configuration = self.configuration;
    return configuration.allowsAirPlayForMediaPlayback;
}

- (void)setSuppressesIncrementalRendering:(BOOL)suppressesIncrementalRendering{
    WKWebViewConfiguration * configuration = self.configuration;
    configuration.suppressesIncrementalRendering = suppressesIncrementalRendering;
}

- (BOOL)suppressesIncrementalRendering{
    WKWebViewConfiguration * configuration = self.configuration;
    return configuration.suppressesIncrementalRendering;
}
- (void)setAllowsPictureInPictureMediaPlayback:(BOOL)allowsPictureInPictureMediaPlayback{
    WKWebViewConfiguration * configuration = self.configuration;
    configuration.allowsPictureInPictureMediaPlayback = allowsPictureInPictureMediaPlayback;
}

- (BOOL)allowsPictureInPictureMediaPlayback{
    WKWebViewConfiguration * configuration = self.configuration;
    return configuration.allowsPictureInPictureMediaPlayback;
}

- (void)setKeyboardDisplayRequiresUserAction:(BOOL)keyboardDisplayRequiresUserAction{
}

- (BOOL)keyboardDisplayRequiresUserAction{
    return NO;
}
- (void)setPaginationMode{}
- (UIWebPaginationMode)paginationMode{
    return UIWebPaginationModeUnpaginated;
}

- (void)setPaginationBreakingMode{}
- (UIWebPaginationBreakingMode)paginationBreakingMode{
    return UIWebPaginationBreakingModePage;
}

#pragma mark- WKNavigationDelegate
-(void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    BOOL resultBOOL = [self callback_webViewShouldStartLoadWithRequest:navigationAction.request navigationType:navigationAction.navigationType];
    if(resultBOOL)
    {
        if(navigationAction.targetFrame == nil)
        {
            [webView loadRequest:navigationAction.request];
        }
        decisionHandler(WKNavigationActionPolicyAllow);
    }
    else
    {
        decisionHandler(WKNavigationActionPolicyCancel);
    }
}
-(void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
{
    [self callback_webViewDidStartLoad];
}
-(void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    [self callback_webViewDidFinishLoad];
}
- (void)webView:(WKWebView *) webView didFailProvisionalNavigation: (WKNavigation *) navigation withError: (NSError *) error
{
    [self callback_webViewDidFailLoadWithError:error];
}
- (void)webView: (WKWebView *)webView didFailNavigation:(WKNavigation *) navigation withError: (NSError *) error
{
    [self callback_webViewDidFailLoadWithError:error];
}

#pragma mark- CALLBACK IMYVKWebView Delegate

- (void)callback_webViewDidFinishLoad
{
    if([self.delegate respondsToSelector:@selector(webViewDidFinishLoad:)])
    {
        [self.delegate webViewDidFinishLoad:(UIWebView *)self];
    }
}
- (void)callback_webViewDidStartLoad
{
    if([self.delegate respondsToSelector:@selector(webViewDidStartLoad:)])
    {
        [self.delegate webViewDidStartLoad:(UIWebView *)self];
    }
}
- (void)callback_webViewDidFailLoadWithError:(NSError *)error
{
    if([self.delegate respondsToSelector:@selector(webView:didFailLoadWithError:)])
    {
        [self.delegate webView:(UIWebView *)self didFailLoadWithError:error];
    }
}
-(BOOL)callback_webViewShouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(NSInteger)navigationType
{
    BOOL resultBOOL = YES;
    if([self.delegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)])
    {
        if(navigationType == -1) {
            navigationType = UIWebViewNavigationTypeOther;
        }
        resultBOOL = [self.delegate webView:(UIWebView *)self shouldStartLoadWithRequest:request navigationType:navigationType];
    }
    return resultBOOL;
}


#pragma mark - unfinish

- (void)setPageLength{}
- (CGFloat)pageLength{
    return 100;
}
- (void)setGapBetweenPages{}
- (CGFloat)gapBetweenPages{
    return 10;
}
- (NSInteger)pageCount{
    return 10;
}
- (void)setScalesPageToFit:(BOOL)scalesPageToFit{}
- (BOOL)scalesPageToFit{ return NO;}
- (void)setDetectsPhoneNumbers:(BOOL)detectsPhoneNumbers{}
- (BOOL)detectsPhoneNumbers{ return NO;}
- (void)setDataDetectorTypes:(UIDataDetectorTypes)dataDetectorTypes{}
- (UIDataDetectorTypes)dataDetectorTypes{return UIDataDetectorTypePhoneNumber;}


@end
