//
//  CSMainViewController.h
//  CloudSeeder
//
//  Created by David Shu on 3/23/12.
//  Copyright (c) 2012 Retronyms. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CSCloudSeeder.h"

typedef enum {
    kCSNav_News = 0,
    kCSNav_FeaturedTracks,
    kCSNav_PopularTracks,
    kCSNav_LatestTracks,
    kCSNav_MyUploads,
    kCSNav_MyActivity,
    kCSNav_Following,
    kCSNav_Count              // Must be last!
} CSNavIndex;

@class CSTrackListViewController;
@class CSActivityListViewController;
@class CSTrackViewController;
@class CSNeedsLoginView;
@class SCShareViewController;
@class ASINetworkQueue;
@interface CSMainViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate> {
    // UI
    // Top level
    IBOutlet UIBarButtonItem *mTitleLabel;
    IBOutlet UIToolbar *mToolbar;
    IBOutlet UIView *mSideView;
    CGRect mDetailViewFrame;
    // Sidebar
    CSNavIndex mStartNavIndex;
    IBOutlet UITableView *mNavTable;
    NSArray *mNavList;
    IBOutlet UIButton *mLoginButton;
    IBOutlet UILabel *mPoweredByLabel;
    IBOutlet UILabel *mSoundCloudLabel;
    // Account view
    IBOutlet UIView *mAccountView;
    IBOutlet UIImageView *mAccountBackground;
    IBOutlet UIImageView *mAvatarImage;
    IBOutlet UILabel *mUserLabel;
    IBOutlet UILabel *mNumTracksLabel;
    IBOutlet UILabel *mFollowingNumPeopleLabel;
    IBOutlet UILabel *mNumFollowersLabel;
    IBOutlet UILabel *mNumILikedLabel;
    // Join message view
    IBOutlet UIView *mJoinMessageView;
    IBOutlet UIImageView *mJoinMessageIcon;
    IBOutletCollection(UILabel) NSArray *mJoinMessageLabels;
    
    // Track list view
    UIViewController *mSubController;
    CSTrackViewController *mTrackViewController;
    CSTrackListViewController *mTrackListViewController;
    CSActivityListViewController *mActivityListViewController;

    // "Modal" views
    // Spinner view
    UIView *mSpinnerView;
    // Needs login view
    UIView *mNeedsLoginView;
    IBOutlet UIButton *mNeedsLoginButton;
    IBOutlet UILabel *mNeedsLoginLabel;
    // Empty my uploads view
    UIView *mEmptyMyUploadsView;
    IBOutlet UILabel *mEmptyMyUploadsLabel;
}
@property (nonatomic, assign) CSNavIndex startNavIndex;
@property (nonatomic, readonly, getter = trackListViewController) CSTrackListViewController *trackListViewController;
@property (nonatomic, readonly, getter = activityListViewController) CSActivityListViewController *activityListViewController;
@property (nonatomic, readonly, getter = trackViewController) CSTrackViewController *trackViewController;
@property (nonatomic, readonly, getter = spinnerView) UIView *spinnerView;
@property (nonatomic, readonly, getter = needsLoginView) UIView *needsLoginView;
@property (nonatomic, readonly, getter = emptyMyUploadsView) UIView *emptyMyUploadsView;
@property (nonatomic, retain) UIViewController *subController;

// Main view controller
- (void)presentLogin;
- (void)presentSubController:(UIViewController *)aSubController;
- (void)showSpinner:(BOOL)doShow animated:(BOOL)animated;
- (void)showError:(CSErrorType)err;

// IBActions
- (IBAction)accountAvatarTapped:(id)sender;
- (IBAction)doneTapped:(id)sender;
- (IBAction)loginTapped:(id)sender;
// Side view
- (IBAction)loginToggleTapped:(id)sender;

@end