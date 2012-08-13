//
//  CSTrackViewController.h
//  CloudSeeder
//
//  Created by David Shu on 3/23/12.
//  Copyright (c) 2012 Retronyms. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "CSCloudSeeder.h"
#import "CSKeyboardTextField.h"

@class SCAudioStream;
@class CSTrack, CSUser, CSApp;
@class CSMainViewController;
@interface CSTrackViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, CSKeyboardTextFieldDelegate, UIActionSheetDelegate> {
    // Track Data
    CSTrack *mTrack;
    CSUser *mArtist;
    CSApp *mCreatedWithApp;
    NSUInteger mTotalTime;
    BOOL mIsFollowingArtist;
    NSMutableArray *mRequests;

    // Audio Stream
    SCAudioStream *mAudioStream;
    NSTimer *mPlaybackTimer;
    CABasicAnimation *mStreamSpinAnimation;
    float mPrevBufferProgress;

    IBOutlet UIView *mTrackView;
    IBOutlet UIImageView *mArtistAvatarImage;
    IBOutlet UILabel *mArtistNameLabel;
    IBOutlet UIButton *mFollowButton;
    IBOutlet UIButton *mViewOnSoundCloudButton;
    // Track
    IBOutlet UILabel *mTrackLabel;
    IBOutlet UIImageView *mTrackImage;
    // Player Controls
    IBOutlet UIButton *mPlayButton;
    IBOutlet UIButton *mLoopButton;
    IBOutlet UIImageView *mStreamSpinner;
    IBOutlet UILabel *mTimeElapsedLabel;
    IBOutlet UILabel *mTimeLeftLabel;
    // Sharing
    IBOutlet UIButton *mLikeButton;
    IBOutlet UIButton *mCommentButton;
    // Not doing sharing right now -dave
//    IBOutlet UIButton *mFacebookButton;
//    IBOutlet UIButton *mTwitterButton;
//    IBOutlet UIButton *mTumblrButton;
    // Comments/likes
    IBOutlet UIImageView *mCommentIcon;
    IBOutlet UIImageView *mLikeIcon;
    IBOutlet UIView *mCommentsView;
    IBOutlet UILabel *mNumCommentsLabel;
    IBOutlet UILabel *mNumLikesLabel;
    IBOutlet UITableView *mCommentsTable;
    // CloudSeeder Select
    IBOutlet UIView *mAppSummaryView;
    IBOutlet UILabel *mAppSummaryLabel;
    IBOutlet UIButton *mGetAppButton;
    IBOutlet UIImageView *mAppIcon;
    // Keyboard
    UIView *mKbParentView;

    CSMainViewController *mCloudSeederController;
}
@property (nonatomic, retain) CSTrack *track;
@property (nonatomic, readonly) NSMutableArray *commentsList;
@property (nonatomic, readonly) NSMutableArray *likesList;
@property (nonatomic, readonly, getter = isLoopOn) BOOL isLoopOn;
@property (nonatomic, assign) CSMainViewController *cloudSeederController;

- (void)refresh;
- (BOOL)isMyTrack;
- (void)killPlayer;
- (IBAction)appIconTapped:(id)sender;
- (IBAction)artistAvatarTapped:(id)sender;
- (IBAction)playTapped:(id)sender;
- (IBAction)loopTapped:(id)sender;
- (IBAction)followTapped:(id)sender;
- (IBAction)viewOnSoundCloudTapped:(id)sender;
- (IBAction)likeTapped:(id)sender;
- (IBAction)commentTapped:(id)sender;
//- (IBAction)shareTapped:(id)sender;
- (IBAction)getAppTapped:(id)sender;

@end
