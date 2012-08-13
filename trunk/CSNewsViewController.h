//
//  CSNewsViewController.h
//  CloudSeeder
//
//  Created by David Shu on 3/28/12.
//  Copyright (c) 2012 Retronyms. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CSMainViewController;
@interface CSNewsViewController : UIViewController <UIWebViewDelegate> {
    IBOutlet UIWebView *mWebView;
    NSString *mNetworkErrorHtmlFilename;
    NSString *mURLString;
}
@property (nonatomic, copy) NSString *URLString;
@property (nonatomic, copy) NSString *networkErrorHtmlFilename;
@property (nonatomic, assign) CSMainViewController *cloudSeederController;

- (void)refresh;

@end
