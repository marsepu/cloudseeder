//
//  CSHeadlineViewController.h
//  CloudSeeder
//
//  Created by David Shu on 4/13/12.
//  Copyright (c) 2012 Retronyms. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    kCSHeadlineType_News,
    kCSHeadlineType_CloudSeederStatus,
    kCSHeadlineType_Comment,
    kCSHeadlineType_Like,
    kCSHeadlineType_Count,      // Must be last!
} CSHeadlineType;

@class CSHeadlineViewController;
@protocol CSHeadlineViewControllerDelegate <NSObject>
- (void)headlineViewController:(CSHeadlineViewController *)headlineVC didTapHeadline:(CSHeadlineType)headlineType;
@end

@interface CSHeadlineViewController : UIViewController <UIWebViewDelegate> {
    // Data
    BOOL mIsEndOfListReached;
    NSMutableDictionary *mHeadlineList;
    NSMutableDictionary *mLastViewedHeadlineList;
    CSHeadlineType mHeadlineType;
    BOOL mIsCycling;
    NSMutableArray *mRequests;
    
    id <CSHeadlineViewControllerDelegate> mDelegate;
    
    // UI
    IBOutlet UIButton *mIconButton;
    IBOutlet UIButton *mInvisibleButton;
    CGPoint mIconButtonCenter;
    IBOutlet UILabel *mHeadlineLabel;
    IBOutlet UIActivityIndicatorView *mSpinner;
    IBOutlet UIView *mHeadlineContentView;
    IBOutlet UIView *mHeadlineView;
    
    UIViewController *mPresenterViewController;
}
@property (nonatomic, assign) id <CSHeadlineViewControllerDelegate> delegate;
@property (nonatomic, assign) UIViewController *presenterViewController;
@property (nonatomic, readonly) CSHeadlineType headlineType;
- (void)showCloudSeeder;
- (IBAction)headlineTapped:(id)sender;
- (id)getHeadline:(CSHeadlineType)headlineType;
- (void)refresh;
- (void)stop;
@end
