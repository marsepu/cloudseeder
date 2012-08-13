//
//  CSTrackViewController.m
//  CloudSeeder
//
//  Created by David Shu on 3/23/12.
//  Copyright (c) 2012 Retronyms. All rights reserved.
//

#import "CSTrackViewController.h"
#import "CSTrackListTableViewCell.h"
#import "SCAudioStream.h"
#import "CSCommentTableViewCell.h"
#import "CSCloudSeeder.h"
#import "SCUI.h"
#import "CSMainViewController.h"
#import "UIView+CloudSeeder.h"
#import "CSUser.h"
#import "CSTrack.h"
#import "CSApp.h"

@interface CSTrackViewController (Private)
// Views
- (void)cleanupViews;
- (void)refreshViews;
- (void)updateIsMyTrackViews:(BOOL)isMyTrack;
- (void)updateCloudSeederSelectViews:(BOOL)isSelect;
- (void)showKeyboardTextField:(NSDictionary *)userInfo;
- (void)updateLikeViews:(BOOL)isLike;
- (void)updateFollowingViews:(BOOL)isFollowing;
- (void)colorViews;
// Player
- (void)resetPlayerControls:(BOOL)isLoop;
- (void)animateStreamSpinner;
// CloudSeeder Requests
- (void)cancelRequests;
- (void)requestTrackComments;
- (void)requestTrackLikes;
- (void)requestImageForUser:(NSUInteger)userId;
- (void)requestImage:(NSString *)url trackId:(NSUInteger)trackId;
- (void)requestIsFollowingUser:(NSUInteger)userId;
- (void)requestFollow:(BOOL)doFollow user:(NSUInteger)userId;
//- (void)requestIsFollowingUser:(NSUInteger)userId;
- (void)requestLike:(BOOL)isLike;
// Not doing sharing right now -dave
#if 0
- (void)requestShareTrack:(NSString *)note connections:(NSArray *)connections;
#endif
- (void)requestComment:(NSString *)comment;
- (void)requestAppImage;
@end


#pragma mark - CSTrackViewController
@implementation CSTrackViewController
@synthesize track = mTrack;
@synthesize commentsList;
@synthesize likesList;
@synthesize isLoopOn;
@synthesize cloudSeederController = mCloudSeederController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        mAudioStream = nil;
        mTrack = nil;
        mRequests = [[NSMutableArray alloc] initWithCapacity:20];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(accountDidChange:)
                                                     name:kCSMyAccountDidChangeNotification
                                                   object:nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    [self colorViews];
    
    mCommentsTable.rowHeight = kCSCommentTableViewCellHeight;
    mCommentsView.backgroundColor = self.view.backgroundColor;
    mCommentsView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    mCommentsView.layer.borderWidth = 1.0f;

    mStreamSpinner.alpha = 0.0;
    
    [self refresh];    
}

- (void)cleanupViews {
    [mTrackView release]; mTrackView = nil;
    [mArtistAvatarImage release]; mArtistAvatarImage = nil;
    [mArtistNameLabel release]; mArtistNameLabel = nil;
    [mFollowButton release]; mFollowButton = nil;
    [mViewOnSoundCloudButton release]; mViewOnSoundCloudButton = nil;
    [mTrackLabel release]; mTrackLabel = nil;
    [mTrackImage release]; mTrackImage = nil;
    [mPlayButton release]; mPlayButton = nil;
    [mLoopButton release]; mLoopButton = nil;
    [mStreamSpinner release]; mStreamSpinner = nil;
    [mTimeElapsedLabel release]; mTimeElapsedLabel = nil;
    [mTimeLeftLabel release]; mTimeLeftLabel = nil;
    [mLikeButton release]; mLikeButton = nil;
    [mCommentButton release]; mCommentButton = nil;
    [mCommentIcon release]; mCommentIcon = nil;
    [mLikeIcon release]; mLikeIcon = nil;
    [mCommentsView release]; mCommentsView = nil;
    [mNumCommentsLabel release]; mNumCommentsLabel = nil;
    [mNumLikesLabel release]; mNumLikesLabel = nil;
    [mCommentsTable release]; mCommentsTable = nil;
    [mAppSummaryView release]; mAppSummaryView = nil;
    [mAppSummaryLabel release]; mAppSummaryLabel = nil;
    [mGetAppButton release]; mGetAppButton = nil;
    [mAppIcon release]; mAppIcon = nil;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [self cleanupViews];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    self.track = nil;
    [mAudioStream release];
    [mRequests release];
    
    [self cleanupViews];
    
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}


#pragma mark - Public
- (void)refresh {
    [self cancelRequests];
    
    // Reset state vars
    mIsFollowingArtist = NO;
    mCreatedWithApp = nil;

    if (mTrack && mTrack.streamURL) {
        // Get track info
        mArtist = [[CSCloudSeeder sharedCSCloudSeeder] userForId:mTrack.userId];
        // Handle CloudSeeder Select
        if (mTrack.isCloudSeederSelect) {
            // Set the app that created this select track
            mCreatedWithApp = [[CSCloudSeeder sharedCSCloudSeeder].appList
                               objectForKey:[NSNumber numberWithInt:mTrack.createdWithId]];
        }
    }
    else {
        if (mTrack && !mTrack.streamURL) {
            [mCloudSeederController showError:kCSError_CantStreamTrack];
        }
        // Clear track so it shows a blank page
        self.track = nil;
        // No track info available
        [self refreshViews];
        return;
    }
    
    [self refreshViews];

    // Clean up previous stream
    [self killPlayer];
    
    // Stream
    mLoopButton.selected = YES; // Loop on by default
    mTotalTime = mTrack.duration/1000;
    NSString *streamURLStr = [[CSCloudSeeder sharedCSCloudSeeder] URLString:mTrack.streamURL];
    mAudioStream = [[SCAudioStream alloc] initWithURL:[NSURL URLWithString:streamURLStr]];
    [self resetPlayerControls:NO];

    // Send out requests
    [self requestIsFollowingUser:mArtist.userId];
    [self requestTrackComments];
    [self requestTrackLikes];
    if (mTrack.isCloudSeederSelect) {
        [self requestAppImage];
    }
}


#pragma mark - Set/Get
- (NSArray *)commentsList {
    return [CSCloudSeeder sharedCSCloudSeeder].commentsList;
}

- (NSArray *)likesList {
    return [CSCloudSeeder sharedCSCloudSeeder].likesList;
}

- (BOOL)isLoopOn {
    return mLoopButton.selected;
}

- (BOOL)isMyTrack {
    NSUInteger myId = [[[CSCloudSeeder sharedCSCloudSeeder].myAccount objectForKey:@"id"] intValue];
    if (mArtist && mArtist.userId == myId) {
        return YES;
    }
    return NO;
}


#pragma mark - Audio Stream Player
- (void)resetPlayerControls:(BOOL)isLoop {
    if (isLoop) {
        // Handle loop specific stuff here.
    }
    else {
        [mPlaybackTimer invalidate];
        mPlaybackTimer = nil;
        mPlayButton.selected = NO;
        // resetPlayer is also used to clear player state
//        mLoopButton.selected = NO;
    }
    
    mTimeElapsedLabel.text = @"0:00";
    mTimeLeftLabel.text = [NSString stringWithFormat:@"-%d:%02d", mTotalTime/60, mTotalTime%60];
    mStreamSpinner.alpha = 0.0;
}

- (IBAction)playTapped:(id)sender {
    if (!mAudioStream || mTotalTime<=0) {
        return;
    }
    
    // Kill timer
    [mPlaybackTimer invalidate];
    mPlaybackTimer = nil;

    if (mAudioStream.playState != SCAudioStreamState_Playing) {
        [mAudioStream play];
        mPlayButton.selected = YES;
        
        // Start timer
        mPlaybackTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(handleTimer:) userInfo:nil repeats:YES];
        
        [self animateStreamSpinner];
        [UIView animateWithDuration:0.5
                              delay:0.0
                            options:UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             mStreamSpinner.alpha = 1.0;
                         }
                         completion:nil];
    }
    else {
        [mAudioStream pause];
        mPlayButton.selected = NO;
        
        [UIView animateWithDuration:0.5
                              delay:0.0
                            options:UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             mStreamSpinner.alpha = 0.0;
                         }
                         completion:nil];
    }
}

- (IBAction)loopTapped:(id)sender {
    mLoopButton.selected = !mLoopButton.selected;
}

- (void)animateStreamSpinner {
    if (mStreamSpinAnimation) {
        return;
    }
    
    mStreamSpinAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    mStreamSpinAnimation.duration = 1.0;
    mStreamSpinAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    mStreamSpinAnimation.toValue = [NSNumber numberWithFloat:-M_PI*2.0];
    mStreamSpinAnimation.repeatCount = HUGE_VALF;
    [mStreamSpinner.layer addAnimation:mStreamSpinAnimation forKey:@"spinAnimation"];
}

- (void)handleTimer:(NSTimer *)timer {
    NSInteger seconds = mAudioStream.playPosition/1000;
    mTimeElapsedLabel.text = [NSString stringWithFormat:@"%d:%02d", seconds/60, seconds%60];
    mTimeLeftLabel.text = [NSString stringWithFormat:@"-%d:%02d", (mTotalTime-seconds)/60, (mTotalTime-seconds)%60];
    
    if (mAudioStream.playState == SCAudioStreamState_Stopped) {
        [self resetPlayerControls:self.isLoopOn];
        if (self.isLoopOn) {
            [mAudioStream play];
        }
    }
    
    if (mAudioStream.bufferingProgress < 1.0) {
        [self animateStreamSpinner];
    }
    else if (ABS(1.0-mAudioStream.bufferingProgress) < 0.03) {
        [UIView animateWithDuration:0.5
                              delay:0.0
                            options:UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             mStreamSpinner.alpha = 0.0;
                         }
                         completion:nil];
    }
}

- (void)killPlayer {
    mPrevBufferProgress = 0.0f;
    
    if (mAudioStream) {
        [mAudioStream release];
        mAudioStream = nil;
    }
    
    if (mPlaybackTimer) {
        [mPlaybackTimer invalidate];
        mPlaybackTimer = nil;
    }
}


#pragma mark - Views
- (void)colorViews {
    [mViewOnSoundCloudButton setTitle:CSLocalizedString(@"View on SoundCloud", kCSControlString) forState:UIControlStateNormal];
    [mViewOnSoundCloudButton setBackgroundImage:CSImage(@"btn-primary-lg.png", kCSCustomPrimaryColor) forState:UIControlStateNormal];
    
    // Player
    [mPlayButton setBackgroundImage:CSImage(@"icn-play-primary-lg.png", kCSCustomPrimaryColor) forState:UIControlStateNormal];
    [mPlayButton setBackgroundImage:CSImage(@"icn-pause-primary-lg.png", kCSCustomPrimaryColor) forState:UIControlStateSelected];
    [mLoopButton setBackgroundImage:CSImage(@"icn-loopoff-primary-lg.png", kCSCustomPrimaryColor) forState:UIControlStateNormal];
    [mLoopButton setBackgroundImage:CSImage(@"icn-loop-primary-lg.png", kCSCustomPrimaryColor) forState:UIControlStateSelected];
    mStreamSpinner.image = CSImage(@"spinner-streaming.png", kCSCustomPrimaryColor);
    
    // Sharing
    [mCommentButton setTitle:CSLocalizedString(@"Comment", kCSControlString) forState:UIControlStateNormal];
    [mCommentButton setBackgroundImage:CSImage(@"btn-primary-lg.png", kCSCustomPrimaryColor) forState:UIControlStateNormal];
    
    // Comment box
    mCommentIcon.image = CSImage(@"icn-comment-primary-lg.png", kCSCustomPrimaryColor);
    mLikeIcon.image = CSImage(@"icn-like-primary-lg.png", kCSCustomPrimaryColor);
}


// Updates all non-player views
- (void)refreshViews {
    // Nothing to see here
    if (!mTrack) {
        mTrackView.hidden = YES;
        return;
    }
    mTrackView.hidden = NO;
    
    BOOL isMyTrack = [self isMyTrack];
    [self updateIsMyTrackViews:isMyTrack];
    
    [self updateFollowingViews:mIsFollowingArtist];
    
    // Set artist label
    mArtistNameLabel.text = mArtist.username;
    // Set artist image
    if (mArtist.avatarImage) {
        mArtistAvatarImage.image = mArtist.avatarImage;
    }
    else {
        [self requestImageForUser:mArtist.userId];
    }
    
    // Set track title
    mTrackLabel.text = mTrack.title;
    
    // Set track artwork if it exists
    if (mTrack.artworkURL) {
        [self requestImage:mTrack.artworkURL trackId:mTrack.trackId];
    }
    else {
        mTrackImage.image = [UIImage imageNamed:@"generic-song.png"];
    }
    
    // Like button
    [self updateLikeViews:mTrack.isUserFavorite];
    
    // Comments
    NSString *comments;
    if (mTrack.commentCount == 1) {
        comments = CSLocalizedString(@"%d comment", nil);
    }
    else {
        comments = CSLocalizedString(@"%d comments", nil);        
    }
    mNumCommentsLabel.text = [NSString stringWithFormat:comments, mTrack.commentCount];
    // Likes
    NSString *likes;
    if (mTrack.favoritingsCount == 1) {
        likes = CSLocalizedString(@"%d like", nil);
    }
    else {
        likes = CSLocalizedString(@"%d likes", nil);
    }
    mNumLikesLabel.text = [NSString stringWithFormat:likes, mTrack.favoritingsCount];
    
    [self updateCloudSeederSelectViews:mTrack.isCloudSeederSelect];
}

- (void)updateIsMyTrackViews:(BOOL)isMyTrack {
    if (isMyTrack) {
        mFollowButton.hidden = YES;
    }
    else {
        mFollowButton.hidden = NO;
    }
}

- (void)updateCloudSeederSelectViews:(BOOL)isSelect {
    if (isSelect) {
        [self.view addSubview:mAppSummaryView];
        // Icon image
        mAppIcon.image = mCreatedWithApp.iconImage;
        // App summary
        mAppSummaryLabel.text = [NSString stringWithFormat:CSLocalizedString(@"%@ uses %@, a CloudSeeder App!", nil), mArtist.username, mCreatedWithApp.appName];;
        // Button label
        NSString *buttonStr = [NSString stringWithFormat:@"Get %@", mCreatedWithApp.appName];
        [mGetAppButton setTitle:CSLocalizedString(buttonStr, kCSControlString)
                       forState:UIControlStateNormal];
        
        // Hide user views
        mArtistNameLabel.hidden = YES;
        mArtistAvatarImage.hidden = YES;
        mFollowButton.hidden = YES;
    }
    else {
        [mAppSummaryView removeFromSuperview];
        mAppIcon.image = nil;
        mAppSummaryLabel.text = nil;
        [mGetAppButton setTitle:nil forState:UIControlStateNormal];
        
        // Show user views
        mArtistNameLabel.hidden = NO;
        mArtistAvatarImage.hidden = NO;
    }
}

// Need to have this to preserve highlight state
- (void)updateLikeViews:(BOOL)isLike {
    if (isLike) {
        [mLikeButton setTitle:CSLocalizedString(@"Liked", kCSControlString) forState:UIControlStateNormal];
        [mLikeButton setBackgroundImage:CSImage(@"btn-primary-selected-lg.png", kCSCustomSecondaryColor) forState:UIControlStateNormal];
    }
    else {
        [mLikeButton setTitle:CSLocalizedString(@"Like", kCSControlString) forState:UIControlStateNormal];
        [mLikeButton setBackgroundImage:CSImage(@"btn-primary-lg.png", kCSCustomPrimaryColor) forState:UIControlStateNormal];        
    }
}

- (void)updateFollowingViews:(BOOL)isFollowing {
    if (isFollowing) {
        [mFollowButton setTitle:CSLocalizedString(@"Followed", kCSControlString) forState:UIControlStateNormal];
        [mFollowButton setBackgroundImage:CSImage(@"btn-primary-selected-sm.png", kCSCustomSecondaryColor) forState:UIControlStateNormal];
    }
    else {
        [mFollowButton setTitle:CSLocalizedString(@"Follow", kCSControlString) forState:UIControlStateNormal];
        [mFollowButton setBackgroundImage:CSImage(@"btn-primary-sm.png", kCSCustomPrimaryColor) forState:UIControlStateNormal];        
    }    
}

- (void)showKeyboardTextField:(NSDictionary *)userInfo {
    CSKeyboardTextField *kbTextField = [[CSKeyboardTextField create] autorelease];
    // This parent view is necessary because we're in a modal window
    mKbParentView = [[UIView viewWithRotationTransform] retain];
    [self.view.window addSubview:mKbParentView];
    kbTextField.parentView = mKbParentView;
    kbTextField.userInfo = userInfo;
    kbTextField.delegate = self;
    
    // Show
    [kbTextField showWithKeyboard];
}


#pragma mark - Actions
- (IBAction)followTapped:(id)sender {
    if (![[CSCloudSeeder sharedCSCloudSeeder] isAccountReady]) {
        [mCloudSeederController presentLogin];
        return;
    }
    
    [self requestFollow:!mIsFollowingArtist user:mArtist.userId];
}

- (IBAction)viewOnSoundCloudTapped:(id)sender {
    NSURL *url = [NSURL URLWithString:mTrack.permalinkURL];
    [[UIApplication sharedApplication] openURL:url];
}

- (IBAction)likeTapped:(id)sender {
    if (![[CSCloudSeeder sharedCSCloudSeeder] isAccountReady]) {
        [mCloudSeederController presentLogin];
        return;
    }

    [self requestLike:!mTrack.isUserFavorite];
}

- (IBAction)commentTapped:(id)sender {
    if (![[CSCloudSeeder sharedCSCloudSeeder] isAccountReady]) {
        [mCloudSeederController presentLogin];
        return;
    }
    
    // Handled in keyboardTextFieldDidFinishDismiss
    [self showKeyboardTextField:[NSDictionary dictionaryWithObjectsAndKeys:
                                 @"comment", @"context",
                                 nil]];
}

// Not doing sharing right now -dave
#if 0
- (IBAction)shareTapped:(id)sender {
    if (![[CSCloudSeeder sharedCSCloudSeeder] isAccountReady]) {
        [mCloudSeederController presentLogin];
        return;
    }

    CSShareType shareType;
    if (sender == mFacebookButton) {
        shareType = kCSShare_Facebook;
    }
    else if (sender == mTwitterButton) {
        shareType = kCSShare_Twitter;
    }
    else if (sender == mTumblrButton) {
        shareType = kCSShare_Tumblr;
    }
    else {
        NSAssert(0, @"invalid share type");
    }

    NSArray *shareIds = [[CSCloudSeeder sharedCSCloudSeeder] idsForShareConnection:shareType];
    // Handled in keyboardTextFieldDidFinishDismiss
    [self showKeyboardTextField:[NSDictionary dictionaryWithObjectsAndKeys:
                                 @"share", @"context",
                                 shareIds, @"shareIds",
                                 nil]];
}
#endif

- (IBAction)getAppTapped:(id)sender {
    if (!mCreatedWithApp.externalURL) {
        return;
    }
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:mCreatedWithApp.externalURL]];
}

- (IBAction)appIconTapped:(id)sender {
    if (!mCreatedWithApp.permalinkURL) {
        return;
    }
    
    UIButton *button = (UIButton *)sender;
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:mCreatedWithApp.permalinkURL
                                                             delegate:self
                                                    cancelButtonTitle:nil
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Open in Safari", nil];
    [actionSheet showFromRect:button.frame inView:self.view animated:YES];
    [actionSheet release];
}

- (IBAction)artistAvatarTapped:(id)sender {
    UIButton *button = (UIButton *)sender;
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:mArtist.permalinkURL
                                                             delegate:self
                                                    cancelButtonTitle:nil
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Open in Safari", nil];
    [actionSheet showFromRect:button.frame inView:self.view animated:YES];
    [actionSheet release];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        // Artist avatar image action tapped
        NSURL *url = [NSURL URLWithString:mArtist.permalinkURL];
        [[UIApplication sharedApplication] openURL:url];
    }
}


#pragma mark - UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    CSCommentTableViewCell *cell = (CSCommentTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
		cell = [[CSCommentTableViewCell create] autorelease];
    }
    
    NSDictionary *userDict;
    if (indexPath.section == 0) {
        NSDictionary *commentDict = [self.commentsList objectAtIndex:indexPath.row];
        [cell setIsComment:YES dict:commentDict];
        userDict = [commentDict objectForKey:@"user"];
        
        [cell setCellPositionTypeForRow:indexPath.row totalCount:[self.commentsList count]];
    }
    else if (indexPath.section == 1) {
        userDict = [self.likesList objectAtIndex:indexPath.row];
        [cell setIsComment:NO dict:userDict];
        
        [cell setCellPositionTypeForRow:indexPath.row totalCount:[self.likesList count]];
    }

    if (!cell.imageView.image) {
        [self requestImageForUser:[[userDict objectForKey:@"id"] intValue]];
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return [self.commentsList count];
    }
    else if (section == 1) {
        return [self.likesList count];
    }
    return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"Comments";
    }
    else if (section == 1) {
        return @"Likes";
    }
    return nil;
}


#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 22.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [CSCommentTableViewCell headerViewForSectionWithTitle:[self tableView:tableView titleForHeaderInSection:section]];
}


#pragma mark - KeyboardTextFieldDelegate
- (BOOL)keyboardTextFieldShouldDismiss:(CSKeyboardTextField *)kbTextField {
    // Did user press cancel?
    if (!kbTextField.didConfirmInput) {
        return YES;
    }
    
    if ([kbTextField.textField.text length] <= 0) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:CSLocalizedString(@"Write something!", nil) 
                                                     message:CSLocalizedString(@"Comments can't be empty. Please enter some text.", nil)
                                                    delegate:nil
                                           cancelButtonTitle:CSLocalizedString(@"OK", nil)
                                           otherButtonTitles:nil];
        [av show];
        [av release];
        return NO;
    }
    return YES;
}

- (void)keyboardTextFieldWillDismiss:(CSKeyboardTextField *)kbTextField {
}

- (void)keyboardTextFieldDidFinishDismiss:(CSKeyboardTextField *)kbTextField {
	[kbTextField removeFromSuperview];
    [mKbParentView removeFromSuperview];
    [mKbParentView autorelease];
    
    // Only do something if "Done" pressed
    if (kbTextField.didConfirmInput) {
        NSString *context = [kbTextField.userInfo objectForKey:@"context"];
        if ([context isEqualToString:@"comment"]) {
            NSLog(@"comment = %@", kbTextField.textField.text);
            [self requestComment:kbTextField.textField.text];
        }
        // Not doing sharing right now -dave
#if 0
        else if ([context isEqualToString:@"share"]) {
            NSArray *shareIds = [kbTextField.userInfo objectForKey:@"shareIds"];
            NSLog(@"share ids = %@", shareIds);
            [self requestShareTrack:kbTextField.textField.text connections:shareIds];
        }
#endif
    }
}


#pragma mark - CloudSeeder Requests
- (void)cancelRequests {
    [[CSCloudSeeder sharedCSCloudSeeder] cancelRequests:mRequests];
    [mRequests removeAllObjects];
}

- (void)accountDidChange:(NSNotification *)notification {
    [self refreshViews];
}

- (void)requestTrackComments {
    __block SCRequest *request =
    [[CSCloudSeeder sharedCSCloudSeeder] requestTrackComments:mTrack.trackId
                                                   completion:^(id obj, NSError *error) {
                                                       [mRequests removeObject:request];
                                                       [mCommentsTable reloadData];
                                                       [self refreshViews];
                                                   }];
    [mRequests addObject:request];
}

- (void)requestTrackLikes {
    __block SCRequest *request =
    [[CSCloudSeeder sharedCSCloudSeeder] requestTrackFavoriters:mTrack.trackId
                                                     completion:^(id obj, NSError *error) {
                                                         [mRequests removeObject:request];
                                                         [self refreshViews];
                                                         [mCommentsTable reloadData];        
                                                     }];
    [mRequests addObject:request];
}

- (void)requestImageForUser:(NSUInteger)userId {
    CSUser *user = [[CSCloudSeeder sharedCSCloudSeeder] userForId:userId];
    if (!user) {
        return;
    }

    // Make image request
    __block SCRequest *request =
    [[CSCloudSeeder sharedCSCloudSeeder] requestUserImage:user.avatarURL
                                                   userId:user.userId
                                                imageType:kCSImageURLType_badge
                                               completion:^(id obj, NSError *error) {
                                                   [mRequests removeObject:request];
                                                   if (mArtist.userId == user.userId) {
                                                       mArtistAvatarImage.image = user.avatarImage;
                                                   }
                                                   [mCommentsTable reloadData];
                                               }];
    [mRequests addObject:request];
}

- (void)requestImage:(NSString *)url trackId:(NSUInteger)trackId {
    // Make image request
    __block SCRequest *request =
    [[CSCloudSeeder sharedCSCloudSeeder] requestTrackImage:url
                                                   trackId:trackId
                                                 imageType:kCSImageURLType_t300x300
                                                completion:^(id obj, NSError *error) {
                                                    [mRequests removeObject:request];
                                                    if (!error) {
                                                        if (mTrack.trackId == trackId) {
                                                            mTrackImage.image = obj;
                                                        }
                                                    }
                                                }];
    [mRequests addObject:request];
}

- (void)requestFollow:(BOOL)doFollow user:(NSUInteger)userId {
    __block SCRequest *request =
    [[CSCloudSeeder sharedCSCloudSeeder] requestFollow:doFollow
                                                  user:userId
                                            completion:^(id obj, NSError *error) {
                                                [mRequests removeObject:request];
                                                [mCloudSeederController showSpinner:NO animated:YES];

                                                if (!error) {
                                                    mIsFollowingArtist = [obj boolValue];
                                                    [self updateFollowingViews:mIsFollowingArtist];
                                                }
                                                else {
                                                    [mCloudSeederController showError:kCSError_NoNetwork];
                                                }
                                            }];
    [mRequests addObject:request];
    [mCloudSeederController showSpinner:YES animated:YES];
}

- (void)requestIsFollowingUser:(NSUInteger)userId {
    __block SCRequest *request =
    [[CSCloudSeeder sharedCSCloudSeeder] requestIsFollowingUser:userId
                                                     completion:^(id obj, NSError *error) {
                                                         [mRequests removeObject:request];
                                                         
                                                         if (!error) {
                                                             mIsFollowingArtist = [obj boolValue];
                                                             [self updateFollowingViews:mIsFollowingArtist];
                                                         }
                                                     }];
    [mRequests addObject:request];
}

- (void)requestLike:(BOOL)isLike {
    __block SCRequest *request =
    [[CSCloudSeeder sharedCSCloudSeeder] requestFavorite:isLike
                                                   track:mTrack.trackId
                                              completion:^(id obj, NSError *error) {
                                                  [mRequests removeObject:request];
                                                  [mCloudSeederController showSpinner:NO animated:YES];
                                                  
                                                  if (!error) {
                                                      NSNumber *isOK = (NSNumber *)obj;
                                                      if (isOK) {
                                                          mTrack.isUserFavorite = isLike;
                                                          [self refreshViews];
                                                      }
                                                      
                                                      // Refresh track likes
                                                      [self requestTrackLikes];
                                                  }
                                                  else {
                                                      [mCloudSeederController showError:kCSError_NoNetwork];                                                      
                                                  }
                                              }];
    [mRequests addObject:request];
    [mCloudSeederController showSpinner:YES animated:YES];
}

// Not doing sharing right now -dave
#if 0
- (void)requestShareTrack:(NSString *)note connections:(NSArray *)connections {
    // TODO: do we want to cancel this call?
//    __block SCRequest *request =
    [[CSCloudSeeder sharedCSCloudSeeder] requestShareTrack:mTrack.trackId
                                                  withNote:note
                                             onConnections:connections
                                                completion:^(id obj, NSError *error) {
                                                    NSLog(@"done share. err = %@", error);
                                                    [mCloudSeederController showSpinner:NO animated:YES];
                                                    if (!error) {
                                                        // TODO: share ok
                                                    }
                                                    else {
                                                        [mCloudSeederController showError:kCSError_NoNetwork];
                                                    }
                                                }];
//    [mRequests addObject:request];
    [mCloudSeederController showSpinner:YES animated:YES];
}
#endif

- (void)requestComment:(NSString *)comment {
    [[CSCloudSeeder sharedCSCloudSeeder] requestComment:comment
                                                  track:mTrack.trackId
                                             completion:^(id obj, NSError *error) {
                                                 [mCloudSeederController showSpinner:NO animated:YES];
                                                 if (!error) {
                                                     // Refresh track comments
                                                     [self requestTrackComments];
                                                 }
                                                 else {
                                                     [mCloudSeederController showError:kCSError_NoNetwork];
                                                 }                                                 
                                             }];
    [mCloudSeederController showSpinner:YES animated:YES];
}

- (void)requestAppImage {
    __block AFHTTPRequestOperation *request =
    [[CSCloudSeeder sharedCSCloudSeeder] requestImageAtURL:mCreatedWithApp.iconURL
                                                completion:^(id obj, NSError *error) {
                                                    [mRequests removeObject:request];
                                                    if (!error) {
                                                        mCreatedWithApp.iconImage = (UIImage *)obj;
                                                        [self refreshViews];
                                                    }
                                                }];
    [mRequests addObject:request];
}

@end
