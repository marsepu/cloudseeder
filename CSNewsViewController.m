//
//  CSNewsViewController.m
//  CloudSeeder
//
//  Created by David Shu on 3/28/12.
//  Copyright (c) 2012 Retronyms. All rights reserved.
//

#import "CSNewsViewController.h"
#import "CSMainViewController.h"
#import "UIView+CloudSeeder.h"
#import "CSBundle.h"

@implementation CSNewsViewController
@synthesize URLString = mURLString;
@synthesize cloudSeederController = mCloudSeederController;
@synthesize networkErrorHtmlFilename = mNetworkErrorHtmlFilename;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    // Set up webview
    mWebView.delegate = self;
    
    // Load content
//    if (self.urlString) {
//        [self startLoading];
//    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [mWebView release]; mWebView = nil;
}

- (void)dealloc {
    mWebView.delegate = nil;
    self.networkErrorHtmlFilename = nil;
    self.URLString = nil;
    
    // IBOutlets
    [mWebView release]; mWebView = nil;
    
    [super dealloc];    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

- (void)setIsLoading:(BOOL)aIsLoading {
    // Show spinner view
    [mCloudSeederController showSpinner:aIsLoading animated:YES];
}

- (void)refresh {
	// version
	NSBundle *bundle = [NSBundle mainBundle];
	NSString *appVersion = [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
	if(!appVersion)
		appVersion = @"NA";
	
    NSString *aboutUrl = kCSCustomNewsURL;
	
	CFStringRef preprocessedString =
    CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault,(CFStringRef)aboutUrl, CFSTR(""), kCFStringEncodingUTF8);
	CFStringRef aUrlString =
    CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef) preprocessedString, NULL, NULL, kCFStringEncodingUTF8);
	NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString: (NSString*)aUrlString]];
	[mWebView loadRequest:req];
	
	CFRelease(aUrlString);
	CFRelease(preprocessedString);
    
    self.URLString = (NSString *)aUrlString;
    [self setIsLoading:YES];
}

#pragma mark - UIWebViewDelegate
-(BOOL)webView:(UIWebView *)web_view shouldStartLoadWithRequest:(NSURLRequest *)url_request navigationType:(UIWebViewNavigationType)nt {
    if (nt == UIWebViewNavigationTypeLinkClicked && [[url_request.URL absoluteString] hasPrefix:@"http://"]) {
        [[UIApplication sharedApplication] openURL: url_request.URL];
        return NO;
    }
    
    return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {  
    [self setIsLoading:NO];

    NSString *htmlName = nil;
    if (!mNetworkErrorHtmlFilename) {
        // Use default error page if nothing set
        htmlName = @"cs-news-error";
    }
    else {
        htmlName = [mNetworkErrorHtmlFilename stringByDeletingPathExtension];
    }
    NSString *html_path = [[NSBundle mainBundle] pathForResource:htmlName ofType:@"html"];
    NSString *error_html = [NSString stringWithContentsOfFile:html_path encoding:NSASCIIStringEncoding error:NULL];
//    assert(error_html);
    [mWebView loadHTMLString:error_html baseURL:[[NSBundle mainBundle] resourceURL]];
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [self setIsLoading:YES];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self setIsLoading:NO];
}


@end
