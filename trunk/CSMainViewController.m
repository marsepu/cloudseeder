//
//  CSCloudSeederViewController.m
//  CloudSeeder
//
//  Created by David Shu on 3/23/12.
//  Copyright (c) 2012 Retronyms. All rights reserved.
//

#import "CSMainViewController.h"
#import "CSActivityListViewController.h"
#import "CSTrackListViewController.h"
#import "CSNewsViewController.h"
#import "SCLoginViewController.h"
#import "SCSoundCloud.h"
#import "CSTrackViewController.h"
#import "CSUser.h"
#import "UIView+CloudSeeder.h"
#import "CSBundle.h"
#import "SCUI.h"

// Subclass for smooth selected shadow color
@interface CSNavTableViewCell : UITableViewCell
- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animate;
- (void)setSelected:(BOOL)selected animated:(BOOL)animate;
@end

@implementation CSNavTableViewCell
- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animate {
    self.textLabel.shadowColor = highlighted ? kCSCustomSidebarSelectedTextShadow : kCSCustomSidebarTitleTextShadow;
    [super setHighlighted:highlighted animated:animate];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animate {
    self.textLabel.shadowColor = selected ? kCSCustomSidebarSelectedTextShadow : kCSCustomSidebarTitleTextShadow;
    [super setSelected:selected animated:animate];
}
@end

@interface CSMainViewController (Private)
// Views
- (void)cleanupViews;
- (void)updateLoggedInViews:(BOOL)isLoggedIn animated:(BOOL)animated;
- (void)updateAccountSnapshot;
- (void)setupToolbar;
- (void)setupSidebar;
// Requests
- (void)requestMe;
@end

@implementation CSMainViewController
@synthesize subController = mSubController;
@synthesize startNavIndex = mStartNavIndex;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        // Nav strings
        NSString *featured = [NSString stringWithFormat:@"Featured %@", kCSCustomTrackPluralStr];
        NSString *popular = [NSString stringWithFormat:@"Popular %@", kCSCustomTrackPluralStr];
        NSString *latest = [NSString stringWithFormat:@"Latest %@", kCSCustomTrackPluralStr];
        mNavList = [[NSArray alloc] initWithObjects:
                    CSLocalizedString(@"News", kCSControlString),
                    CSLocalizedString(featured, kCSControlString),
                    CSLocalizedString(popular, kCSControlString),
                    CSLocalizedString(latest, kCSControlString),
                    CSLocalizedString(@"My Uploads", kCSControlString),
                    CSLocalizedString(@"My Activity", kCSControlString),
                    CSLocalizedString(@"Following", kCSControlString),
                    nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(soundCloudAccountDidChange:)
                                                     name:SCSoundCloudAccountDidChangeNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(requestMeUpdate)
                                                     name:kCSMyAccountActivityNotification
                                                   object:nil];
        mStartNavIndex = -1;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    [self setupToolbar];

    mDetailViewFrame = self.view.frame;
    mDetailViewFrame.origin.x = mSideView.frame.size.width;
    mDetailViewFrame.origin.y = mSideView.frame.origin.y;
    mDetailViewFrame.size.height = mSideView.frame.size.height;
    mDetailViewFrame.size.width -= mSideView.frame.size.width;
    NSLog(@"x=%f y=%f w=%f h=%f", mDetailViewFrame.origin.x, mDetailViewFrame.origin.y, mDetailViewFrame.size.width, mDetailViewFrame.size.height);

    // Sidebar init
    [self setupSidebar];
    [self updateLoggedInViews:NO animated:NO];
    mAccountView.backgroundColor = [UIColor clearColor];
    
    mNavTable.rowHeight = 44.0f;
    // Select nav, force delegate call
    if (mStartNavIndex == -1) {
        mStartNavIndex = kCSNav_News;
    }
    NSIndexPath *selected = [NSIndexPath indexPathForRow:mStartNavIndex inSection:0];
    [mNavTable selectRowAtIndexPath:selected animated:NO scrollPosition:UITableViewScrollPositionTop];
    [self tableView:mNavTable didSelectRowAtIndexPath:selected];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([[CSCloudSeeder sharedCSCloudSeeder] isAccountReady]) {
        [self requestMe];
    }
}

- (void)cleanupViews {
    [mSpinnerView release];
    [mNeedsLoginView release];
    [mEmptyMyUploadsView release];

    // IBOutlets
    [mTitleLabel release]; mTitleLabel = nil;
    [mToolbar release]; mToolbar = nil;
    [mSideView release]; mSideView = nil;
    [mNavTable release]; mNavTable = nil;
    [mLoginButton release]; mLoginButton = nil;
    [mAccountView release]; mAccountView = nil;
    [mAccountBackground release]; mAccountBackground = nil;
    [mAvatarImage release]; mAvatarImage = nil;
    [mUserLabel release]; mUserLabel = nil;
    [mNumTracksLabel release]; mNumTracksLabel = nil;
    [mFollowingNumPeopleLabel release]; mFollowingNumPeopleLabel = nil;
    [mNumFollowersLabel release]; mNumFollowersLabel = nil;
    [mNumILikedLabel release]; mNumILikedLabel = nil;
    [mJoinMessageView release]; mJoinMessageView = nil;
    [mJoinMessageIcon release]; mJoinMessageIcon = nil;
    [mNeedsLoginButton release]; mNeedsLoginButton = nil;
    [mEmptyMyUploadsLabel release]; mEmptyMyUploadsLabel = nil;
    [mNeedsLoginLabel release]; mNeedsLoginLabel = nil;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [self cleanupViews];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[CSCloudSeeder sharedCSCloudSeeder] cancelAllRequests];
    [[CSCloudSeeder sharedCSCloudSeeder] clearAllData];
    
    // Data
    [mNavList release];

    // UI
    [mTrackListViewController release];
    [mActivityListViewController release];
    if (mTrackViewController) {
        [mTrackViewController killPlayer];
        [mTrackViewController release];
    }
    self.subController = nil;
    [self cleanupViews];

    [super dealloc];
}


#pragma mark - Public
- (IBAction)doneTapped:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)loginTapped:(id)sender {
    [self presentLogin];
}

- (void)presentLogin {
    // Block the UI in the background
    __block UIView *blocker = [[UIView alloc] init];
    blocker.backgroundColor = [UIColor clearColor];
    [blocker showFullScreen];
    [blocker release];
    
    [SCSoundCloud requestAccessWithPreparedAuthorizationURLHandler:^(NSURL *preparedURL){
        NSLog(@"preparedURL = %@", preparedURL.absoluteURL);
        SCLoginViewController *vc = [SCLoginViewController loginViewControllerWithPreparedURL:preparedURL
                                                                            completionHandler:^(NSError *error) {
                                                                                NSLog(@"done logging in. err=%@", [error localizedDescription]);
                                                                                [blocker removeFromSuperview];
                                                                            }];

        [self presentModalViewController:vc animated:YES];
    }];
}

- (void)showSpinner:(BOOL)doShow animated:(BOOL)animated {
    if (doShow) {
        [self.view addSubview:self.spinnerView];
        self.spinnerView.frame = mDetailViewFrame;
        [self.spinnerView show:doShow animated:animated completion:nil];
    }    
    else {
        [self.spinnerView show:doShow animated:animated completion:^(BOOL finished) {
            [self.spinnerView removeFromSuperview];            
        }];
    }
}

- (void)showError:(CSErrorType)err {
    NSString *title = nil;
    NSString *message = nil;
    switch (err) {
        case kCSError_NoNetwork: {
            title = CSLocalizedString(@"Oops!", nil);
            message = CSLocalizedString(@"There was a problem connecting to SoundCloud. Please check your network connection and try again.", nil);
            break;
        }
        case kCSError_CantStreamTrack: {
            title = CSLocalizedString(@"Oops!", nil);
            message = CSLocalizedString(@"Unfortunately this track can't be streamed.", nil);
            break;            
        }
        default:
            NSAssert(0, @"unknown error");
            break;
    }
    
    for (UIView *v in [[UIApplication sharedApplication].keyWindow subviews]) {
		if([v isKindOfClass:[UIAlertView class]]) {
			return;
        }
    }

    UIAlertView *av = [[UIAlertView alloc] initWithTitle:title
                                                 message:message
                                                delegate:nil
                                       cancelButtonTitle:CSLocalizedString(@"OK", nil)
                                       otherButtonTitles:nil];
    [av show];
    [av release];
}

- (void)presentSubController:(UIViewController *)aSubController {
    if (mSubController) {
        [mSubController.view removeFromSuperview];
    }
    [self.view addSubview:aSubController.view];
    aSubController.view.frame = mDetailViewFrame;
    self.subController = aSubController;

    // Must call this manually since iOS4 doesn't automatically forward 
    [aSubController viewWillAppear:YES];
}


#pragma mark - Set/Get
- (CSActivityListViewController *)activityListViewController {
    if (!mActivityListViewController) {
        mActivityListViewController = [[CSActivityListViewController alloc] initWithNibName:@"CSListViewController" bundle:nil];
        mActivityListViewController.cloudSeederController = self;
    }
    return mActivityListViewController;
}

- (CSTrackListViewController *)trackListViewController {
    if (!mTrackListViewController) {
        mTrackListViewController = [[CSTrackListViewController alloc] initWithNibName:@"CSListViewController" bundle:nil];
        mTrackListViewController.cloudSeederController = self;
    }
    return mTrackListViewController;
}

- (CSTrackViewController *)trackViewController {
    if (!mTrackViewController) {
        mTrackViewController = [[CSTrackViewController alloc] initWithNibName:@"CSTrackViewController" bundle:nil];
        mTrackViewController.cloudSeederController = self;
    }
    return mTrackViewController;
}

- (UIView *)spinnerView {
    if (!mSpinnerView) {
        NSArray *array = [[NSBundle mainBundle] loadNibNamed:@"CSSpinnerView" owner:self options:nil];
        mSpinnerView = [(UIView *)[array objectAtIndex:0] retain];
    }
    return mSpinnerView;
}

- (UIView *)needsLoginView {
    if (!mNeedsLoginView) {
        NSArray *array = [[NSBundle mainBundle] loadNibNamed:@"CSNeedsLoginView" owner:self options:nil];
        mNeedsLoginView = [(UIView *)[array objectAtIndex:0] retain];
        [mNeedsLoginButton setTitle:CSLocalizedString(@"Log in", kCSControlString) forState:UIControlStateNormal];
        mNeedsLoginLabel.text = CSLocalizedString(@"To view your activity, you must be logged in.", nil);
    }
    return mNeedsLoginView;
}

- (UIView *)emptyMyUploadsView {
    if (!mEmptyMyUploadsView) {
        NSArray *array = [[NSBundle mainBundle] loadNibNamed:@"CSEmptyMyUploadsView" owner:self options:nil];
        mEmptyMyUploadsView = [(UIView *)[array objectAtIndex:0] retain];
        NSString *haventShared = [NSString stringWithFormat:@"You haven't shared any %@ yet!", kCSCustomTrackPluralStr];
        mEmptyMyUploadsLabel.text = CSLocalizedString(haventShared, nil);
    }
    return mEmptyMyUploadsView;
}


#pragma mark - Sidebar
- (IBAction)loginToggleTapped:(id)sender {
    if ([[CSCloudSeeder sharedCSCloudSeeder] isAccountReady]) {
        // Log out
        [[CSCloudSeeder sharedCSCloudSeeder] logoutAccount];
    }
    else {
        [self presentLogin];
    }
}

- (IBAction)accountAvatarTapped:(id)sender {
    UIButton *button = (UIButton *)sender;
    NSDictionary *me = [CSCloudSeeder sharedCSCloudSeeder].myAccount;
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:[me objectForKey:@"permalink_url"]
                                                             delegate:self
                                                    cancelButtonTitle:nil
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Open in Safari", nil];
    [actionSheet showFromRect:button.frame inView:mAccountView animated:YES];
    [actionSheet release];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        NSDictionary *me = [CSCloudSeeder sharedCSCloudSeeder].myAccount;
        
        // Artist avatar image action tapped
        NSURL *url = [NSURL URLWithString:[me objectForKey:@"permalink_url"]];
        [[UIApplication sharedApplication] openURL:url];
    }
}


#pragma mark UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"Cell";
	
	CSNavTableViewCell *cell = (CSNavTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[[CSNavTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
	}
    
    cell.textLabel.text = [mNavList objectAtIndex:indexPath.row];
    cell.textLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:11.0f];
    cell.textLabel.textColor = kCSCustomSidebarTitleText;
    cell.textLabel.shadowColor = kCSCustomSidebarTitleTextShadow;
    cell.textLabel.shadowOffset = CGSizeMake(0.0, -1.0);
    // Selected
    cell.textLabel.highlightedTextColor = kCSCustomSidebarSelectedText;
    CGRect f = cell.textLabel.frame;
    f.origin.x = 12.0f;
    cell.textLabel.frame = f;
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [mNavList count];
}


#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case kCSNav_News: {
            CSNewsViewController *newsVC = [[[CSNewsViewController alloc] initWithNibName:@"CSNewsViewController" bundle:nil] autorelease];
            newsVC.cloudSeederController = self;
            [self presentSubController:newsVC];
            [newsVC refresh];
            break;
        }
        case kCSNav_FeaturedTracks: {
            self.trackListViewController.trackListType = kCSTrackList_Featured;
            [self presentSubController:self.trackListViewController];
            [self.trackListViewController refreshAnimated:NO];
            break;
        }
        case kCSNav_PopularTracks: {
            self.trackListViewController.trackListType = kCSTrackList_Popular;
            [self presentSubController:self.trackListViewController];
            [self.trackListViewController refreshAnimated:NO];
            break;
        }        
        case kCSNav_LatestTracks: {
            self.trackListViewController.trackListType = kCSTrackList_Latest;
            [self presentSubController:self.trackListViewController];
            [self.trackListViewController refreshAnimated:NO];
            break;
        }
        case kCSNav_MyUploads: {
            self.trackListViewController.trackListType = kCSTrackList_MyUploads;
            [self presentSubController:self.trackListViewController];
            [self.trackListViewController refreshAnimated:NO];
            break;
        }
        case kCSNav_MyActivity: {
            [self presentSubController:self.activityListViewController];
            [self.activityListViewController refreshAnimated:NO];
            break;
        }
        case kCSNav_Following: {
            self.trackListViewController.trackListType = kCSTrackList_Following;
            [self presentSubController:self.trackListViewController];
            [self.trackListViewController refreshAnimated:NO];
            break;
        }            
        default:
            break;
    }
}


#pragma mark - Private
- (void)updateLoggedInViews:(BOOL)isLoggedIn animated:(BOOL)animated {
    CGFloat y = CGRectGetMaxY(mNavTable.frame) + 20.0;
    
    UIView *oldView, *newView;
    if (isLoggedIn) {
        // Logging in: account view coming in, join message view going out
        newView = mAccountView;
        oldView = mJoinMessageView;
        
        [mSideView addSubview:mAccountView];
        
        [mLoginButton setTitle:CSLocalizedString(@"Log out", kCSControlString) forState:UIControlStateNormal];        
    }
    else {
        // Logging out: join message coming in, account view going out
        newView = mJoinMessageView;
        oldView = mAccountView;
        
        [mSideView addSubview:mJoinMessageView];
        
        [mLoginButton setTitle:CSLocalizedString(@"Get started now", kCSControlString) forState:UIControlStateNormal];        
    }

    // Animation
    void (^snapshotAction)(void) = ^{  
        // Move old view to the right
//        CGRect ovf = oldView.frame;
//        ovf.origin.x = mSideView.frame.size.width/2.0;
//        ovf.origin.y = y;   // Under nav table
//        oldView.frame = CGRectIntegral(ovf);

        // New view
//        CGRect frame = newView.frame;
//        frame.origin.x = CGRectGetMidX(mSideView.frame) - (newView.frame.size.width/2.0);
//        frame.origin.y = y; // Under nav table
//        newView.frame = CGRectIntegral(frame);

        // Position login button under new view
        CGRect frame = mLoginButton.frame;
        frame.origin.x = CGRectGetMidX(newView.frame) - (mLoginButton.frame.size.width/2.0);
        frame.origin.y = CGRectGetMaxY(newView.frame) + 15.0;
        mLoginButton.frame = CGRectIntegral(frame);

        newView.alpha = 1.0;
        oldView.alpha = 0.0;
    };
    
    // Animation done
    void (^snapshotDoneAction)(BOOL finished) = ^(BOOL finished) {
        if (!isLoggedIn) {
            // Clear account UI
            mUserLabel.text = @"";
            mAvatarImage.image = [UIImage imageNamed:@"generic-avatar.png"];
            mNumTracksLabel.text = @"";
            mFollowingNumPeopleLabel.text = @"";
            mNumFollowersLabel.text = @"";
            mNumILikedLabel.text = @"";
        }
    };
    
    CGRect frame = newView.frame;
    frame.origin.x = CGRectGetMidX(mSideView.frame) - (newView.frame.size.width/2.0);
    frame.origin.y = y; // Under nav table
    newView.frame = CGRectIntegral(frame);
    
    // Call everything here
    if (animated) {
        // New view starts from the left and can't be seen
//        CGRect cvf = newView.frame;
//        cvf.origin.x = -mSideView.frame.size.width/2.0;
//        cvf.origin.y = y;   // Under nav table
//        newView.frame = cvf;
        newView.alpha = 0.0;
        oldView.alpha = 1.0;
        [UIView animateWithDuration:0.3
                              delay:0.0
                            options:UIViewAnimationOptionAllowUserInteraction
                         animations:snapshotAction
                         completion:snapshotDoneAction];
    }
    else {
        snapshotAction();
        snapshotDoneAction(YES);
    }
}

- (void)updateAccountSnapshot {
    NSDictionary *me = [CSCloudSeeder sharedCSCloudSeeder].myAccount;
    mUserLabel.text = [me objectForKey:@"username"];
    
    // Track count
    NSUInteger trackCount = [[me objectForKey:@"track_count"] intValue];
    NSString *str;
    if (trackCount == 1) {
        str = [NSString stringWithFormat:@"%d %@", trackCount, kCSCustomTrackStr];
    }
    else {
        str = [NSString stringWithFormat:@"%d %@", trackCount, kCSCustomTrackPluralStr];
    }
    mNumTracksLabel.text = CSLocalizedString(str, nil);
    
    // Num people following me
    NSUInteger followingsCount = [[me objectForKey:@"followings_count"] intValue];
    if (followingsCount == 1) {
        str = [NSString stringWithFormat:@"Following %d person", followingsCount];        
    }
    else {
        str = [NSString stringWithFormat:@"Following %d people", followingsCount];
    }
    mFollowingNumPeopleLabel.text = CSLocalizedString(str, nil);
    
    NSUInteger followersCount = [[me objectForKey:@"followers_count"] intValue];
    if (followersCount == 1) {
        str = [NSString stringWithFormat:@"%d follower", followersCount];
    }
    else {
        str = [NSString stringWithFormat:@"%d followers", followersCount];
    }
    mNumFollowersLabel.text = CSLocalizedString(str, nil);
    
    NSUInteger likeCount = [[me objectForKey:@"public_favorites_count"] intValue];
    if (likeCount == 1) {
        str = [NSString stringWithFormat:@"Liked %d %@", likeCount, kCSCustomTrackStr];        
    }
    else {
        str = [NSString stringWithFormat:@"Liked %d %@", likeCount, kCSCustomTrackPluralStr];        
    }
    mNumILikedLabel.text = CSLocalizedString(str, nil);
}

- (void)setupToolbar {    
    mToolbar.barStyle = kCSCustomToolbarStyle;

    NSMutableArray *items = [NSMutableArray arrayWithCapacity:5];
    
    UIBarButtonItem *spaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    spaceItem.width = 56.0;
    [items addObject:spaceItem];
    [spaceItem release];
    
    UIBarButtonItem *flexItem0 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [items addObject:flexItem0];
    [flexItem0 release];
    
    // Untappable toolbar title
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 400, 44)];
    NSString *titleStr = [NSString stringWithFormat:@"%@ community", kCSCustomTitleStr];
    titleLabel.text = CSLocalizedString(titleStr, kCSControlString);
    titleLabel.font = [UIFont boldSystemFontOfSize:20.0];
    titleLabel.textAlignment = UITextAlignmentCenter;
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.textColor = kCSCustomSidebarTitleText;
    UIBarButtonItem *titleItem = [[UIBarButtonItem alloc] initWithCustomView:titleLabel];
    [items addObject:titleItem];
    [titleLabel release];
    [titleItem release];
    
    UIBarButtonItem *flexItem1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [items addObject:flexItem1];
    [flexItem1 release];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneTapped:)];
    doneButton.title = CSLocalizedString(@"Done", kCSControlString);
    [items addObject:doneButton];
    [doneButton release];
    
    [mToolbar setItems:items animated:NO];
}

- (void)setupSidebar {
    mJoinMessageView.backgroundColor = [UIColor clearColor];

    UILabel *label = [mJoinMessageLabels objectAtIndex:0];
    NSString *str = [NSString stringWithFormat:@"Join the %@ Community!", kCSCustomTitleStr];
    label.text = CSLocalizedString(str, nil);
    label.textColor = kCSCustomSidebarText;
    
    label = [mJoinMessageLabels objectAtIndex:1];
    label.text = CSLocalizedString(@"* Upload your music", nil);
    label.textColor = kCSCustomSidebarText;
    
    label = [mJoinMessageLabels objectAtIndex:2];
    str = [NSString stringWithFormat:@"* Listen to other %@", kCSCustomTrackPluralStr];
    label.text = CSLocalizedString(str, nil);
    label.textColor = kCSCustomSidebarText;

    label = [mJoinMessageLabels objectAtIndex:3];
    label.text = CSLocalizedString(@"* Post & read comments", nil);
    label.textColor = kCSCustomSidebarText;

    label = [mJoinMessageLabels objectAtIndex:4];
    label.text = CSLocalizedString(@"* View activity on your uploads", nil);
    label.textColor = kCSCustomSidebarText;
    
    label = [mJoinMessageLabels objectAtIndex:5];
    str = [NSString stringWithFormat:@"* Connect with other %@ artists", kCSCustomTitleStr];
    label.text = CSLocalizedString(str, nil);
    label.textColor = kCSCustomSidebarText;
    
    mUserLabel.textColor = kCSCustomSidebarTitleText;
    [mLoginButton setBackgroundImage:CSImage(@"btn-accent.png", kCSCustomSecondaryColor) forState:UIControlStateNormal];
    mJoinMessageIcon.image = [UIImage imageNamed:kCSCustomJoinIcon];
    
    // Colors
    mNavTable.backgroundColor = kCSCustomSidebarBG;
    mNavTable.separatorColor = kCSCustomTableSeparatorColor;
    mSideView.backgroundColor = kCSCustomSidebarBG;
    mPoweredByLabel.textColor = kCSCustomSidebarText;
    mSoundCloudLabel.textColor = kCSCustomSidebarText;
    
    // Account colors
    mNumTracksLabel.textColor = kCSCustomSidebarText;
    mFollowingNumPeopleLabel.textColor = kCSCustomSidebarText;
    mNumFollowersLabel.textColor = kCSCustomSidebarText;
    mNumILikedLabel.textColor = kCSCustomSidebarText;
    mAccountBackground.image = [UIImage imageNamed:kCSCustomAccountBGImage];
}

#pragma mark - CloudSeeder Requests
- (void)requestMe {
    [[CSCloudSeeder sharedCSCloudSeeder] requestMe:^(id obj, NSError *error) {
        if (error) {
            [[CSCloudSeeder sharedCSCloudSeeder] logoutAccount];
            [self showError:kCSError_NoNetwork];
            return;
        }
        
        [self updateAccountSnapshot];
        [self updateLoggedInViews:YES animated:YES];

        NSDictionary *me = [CSCloudSeeder sharedCSCloudSeeder].myAccount;
        [[CSCloudSeeder sharedCSCloudSeeder] requestUserImage:[me objectForKey:@"avatar_url"]
                                                       userId:[[me objectForKey:@"id"] intValue]
                                                    imageType:kCSImageURLType_large
                                                   completion:^(id obj, NSError *error) {
                                                       CSUser *user = (CSUser *)obj;
                                                       NSLog(@"User account avatar image request done. %@", user);
                                                       if (!error && user && user.avatarImage) {
                                                           mAvatarImage.image = user.avatarImage;
                                                       }
                                                   }];        
        // Not doing sharing right now -dave
#if 0
        [[CSCloudSeeder sharedCSCloudSeeder] requestMeConnections:^(id obj, NSError *error) {
        }];
#endif
    }];
}

- (void)requestMeUpdate {
    [[CSCloudSeeder sharedCSCloudSeeder] requestMeUpdate:^(id obj, NSError *error) {
        if (!error) {
            [self updateAccountSnapshot];
        }
        // Don't do anything if error
    }];    
}

- (void)soundCloudAccountDidChange:(NSNotification *)notification {
    if ([[CSCloudSeeder sharedCSCloudSeeder] isAccountReady]) {
        [self requestMe];        
    }
    else {
        [self updateLoggedInViews:NO animated:YES];
    }
}

@end

