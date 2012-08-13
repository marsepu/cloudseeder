//
//  CSHeadlineViewController.m
//  CloudSeeder
//
//  Created by David Shu on 4/13/12.
//  Copyright (c) 2012 Retronyms. All rights reserved.
//

#import "CSHeadlineViewController.h"
#import "UIViewController+CloudSeeder.h"
#import "CSCloudSeeder.h"
#import "CSMainViewController.h"
#import "CSTrack.h"

#define kCSHeadlineTimeInterval (10.0)

NSString * const kCSHeadlineViewController = @"kCSHeadlineViewController";
NSString * const kHeadlineKeys[] = {
    @"news",
    @"cloudseeder_status",
    @"comment",
    @"favoriting"
};

NSString * const kHeadlineImages[] = {
    @"cs-icn-news.png",
    @"feed-icn-scnews.png",
    @"feed-icn-comments.png",
    @"feed-icn-likes.png"
};

@interface CSHeadlineViewController ()
- (void)beginCycling;
- (void)stopCycling;
// Views
- (void)cleanupViews;
- (void)setIsLoading:(BOOL)aIsLoading;
- (void)showHeadline:(CSHeadlineType)headlineType animated:(BOOL)animated;
// Get/Set headlines
- (BOOL)setHeadline:(CSHeadlineType)headlineType data:(id)data;
- (NSMutableDictionary *)loadLastViewedHeadlines;
// Last viewed activites
- (void)saveHeadlines;
// Requests
- (void)requestMe;
- (void)requestMeActivities:(BOOL)isFromBeginning;
- (void)requestTracksForMeActivites;
- (void)requestLatestTrack;
- (void)requestNewsHeadline;
@end

@implementation CSHeadlineViewController
@synthesize delegate = mDelegate;
@synthesize presenterViewController = mPresenterViewController;
@synthesize headlineType = mHeadlineType;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        mHeadlineList = [[NSMutableDictionary alloc] initWithCapacity:4];
        mLastViewedHeadlineList = [[self loadLastViewedHeadlines] retain];
        mRequests = [[NSMutableArray alloc] initWithCapacity:2];
        
        mIsCycling = NO;
        NSLog(@"mLastViewedHeadlineList=%@", mLastViewedHeadlineList);
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.view.opaque = NO;
    self.view.backgroundColor = [UIColor clearColor];
    
    mHeadlineType = -1;
    [self showHeadline:kCSHeadlineType_News animated:NO];
}

- (void)cleanupViews {
    [mIconButton release]; mIconButton = nil;
    [mHeadlineLabel release]; mHeadlineLabel = nil;
    [mSpinner release]; mSpinner = nil;
    [mHeadlineContentView release]; mHeadlineContentView = nil;
    [mInvisibleButton release]; mInvisibleButton = nil;
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    
    [self cleanupViews];
}

- (void)dealloc {
    [self cleanupViews];

    [self stop];
    
    [mHeadlineList release];
    [mLastViewedHeadlineList release];
    [mRequests release];
    
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}


#pragma mark - Public
- (void)refresh {
    if ([mRequests count] > 0) {
        return;
    }
    
    // Clear all activity data and request again
    [mHeadlineList removeAllObjects];
    [self requestNewsHeadline];
    [self requestLatestTrack];
    [self requestMe];
    
    if (!mIsCycling) {
        [self beginCycling];
    }
}

- (void)stop {
    [self stopCycling];
    [[CSCloudSeeder sharedCSCloudSeeder] cancelRequests:mRequests];
    [mRequests removeAllObjects];
}

- (void)beginCycling {
    mIsCycling = YES;
    
    // Next
    int next = mHeadlineType+1;
    for (; next < kCSHeadlineType_Count; next++) {
        if ([self getHeadline:next] != nil) {
            break;
        }
    }
    if (next >= kCSHeadlineType_Count) {
        next = 0;
    }

    [self showHeadline:next animated:YES];
        
    [self performSelector:@selector(beginCycling) withObject:nil afterDelay:kCSHeadlineTimeInterval];
}

- (void)stopCycling {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(beginCycling) object:nil];
    mIsCycling = NO;
}

- (void)showCloudSeeder {
//    [self stopCycling];
    [self saveHeadlines];
    
    if ([mDelegate conformsToProtocol:@protocol(CSHeadlineViewControllerDelegate)]) {
        [mDelegate headlineViewController:self didTapHeadline:mHeadlineType];
    }
    
    CSMainViewController *vc = [[CSMainViewController alloc] initWithNibName:@"CSMainViewController" bundle:nil];
    [mPresenterViewController presentModalViewController:vc frame:vc.view.frame animated:YES];
    [vc release];
}
- (IBAction)headlineTapped:(id)sender {
    [self showCloudSeeder];
}


#pragma mark - Headline data
- (id)getHeadline:(CSHeadlineType)headlineType {
    return [mHeadlineList objectForKey:kHeadlineKeys[headlineType]];
}

- (BOOL)setHeadline:(CSHeadlineType)headlineType data:(id)data {
    BOOL didSet = NO;
    // Only set the headline if its one the user hasn't seen before
    NSString *old = [mLastViewedHeadlineList objectForKey:kHeadlineKeys[headlineType]];
    if (!old || ![old isEqualToString:data]) {
        [mHeadlineList setObject:data forKey:kHeadlineKeys[headlineType]];
        didSet = YES;
    }
    return didSet;
}

- (NSMutableDictionary *)loadLastViewedHeadlines {
    id obj = [[NSUserDefaults standardUserDefaults] objectForKey:kCSHeadlineViewController];
    return [NSMutableDictionary dictionaryWithDictionary:(NSDictionary *)obj];
}

- (void)saveHeadlines {
    // Merge activity lists and save headlines the user has seen
    [mLastViewedHeadlineList addEntriesFromDictionary:mHeadlineList];
    // Don't save news
    [mLastViewedHeadlineList removeObjectForKey:kHeadlineKeys[kCSHeadlineType_News]];
    NSLog(@"save mLastViewedHeadlineList = %@", mLastViewedHeadlineList);

    [[NSUserDefaults standardUserDefaults] setObject:mLastViewedHeadlineList
                                              forKey:kCSHeadlineViewController];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


#pragma mark - View
- (void)setIsLoading:(BOOL)aIsLoading {
    mSpinner.hidden = !aIsLoading;
}

- (UIView *)addHeadlineView {
    UIView *headlineView;
    // Clean up previous
    [mIconButton release]; mIconButton = nil;
    [mHeadlineLabel release]; mHeadlineLabel = nil;
    [mHeadlineContentView release]; mHeadlineContentView = nil;
    [mHeadlineView release]; mHeadlineView = nil;
    
    // Make new headline view
    NSArray *array = [[NSBundle mainBundle] loadNibNamed:@"CSHeadlineView" owner:self options:nil];
    headlineView = (UIView *)[array objectAtIndex:0];
    mHeadlineView.opaque = NO;
    mHeadlineView.backgroundColor = [UIColor clearColor];
    mHeadlineContentView.opaque = NO;
    mHeadlineContentView.backgroundColor = [UIColor clearColor];
    mHeadlineLabel.opaque = NO;
    mHeadlineLabel.backgroundColor = [UIColor clearColor];

    mIconButtonCenter = mIconButton.center;
    [mIconButton addTarget:self action:@selector(headlineTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:headlineView];
    headlineView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    
    [self.view bringSubviewToFront:mSpinner];
    [self.view bringSubviewToFront:mInvisibleButton];
    
    return headlineView;
}

- (void)showHeadline:(CSHeadlineType)headlineType animated:(BOOL)animated {
    if (headlineType != mHeadlineType) {
        UIView *prevHeadlineView = mHeadlineView;
        mHeadlineView = [self addHeadlineView];
        
        // Set headline UI
        UIImage *image = nil;
        if (headlineType < kCSHeadlineType_Count) {
            self.view.hidden = NO;
            [mHeadlineContentView addSubview:mHeadlineLabel];
            image = [UIImage imageNamed:kHeadlineImages[headlineType]];
            mHeadlineLabel.text = [self getHeadline:headlineType];
        }
        else {
            // Show nothing
            self.view.hidden = YES;
        }
        [mIconButton setBackgroundImage:image forState:UIControlStateNormal];
        mIconButton.frame = CGRectMake(0, 0, image.size.width, image.size.height);
        mIconButton.center = mIconButtonCenter;
        
        mHeadlineType = headlineType;
        
        // New headline view starts below and invisible
        mHeadlineView.alpha = 0.0;
        CGRect f = mHeadlineView.frame;
        f.origin.y = self.view.frame.size.height;
        mHeadlineView.frame = f;
        
        void (^headlineAction)(void) = ^{ 
            CGRect f;
            prevHeadlineView.alpha = 0.0;
            f = self.view.frame;
            f.origin.x = 0.0;
            f.origin.y = -self.view.frame.size.height;
            prevHeadlineView.frame = f;
            
            mHeadlineView.alpha = 1.0;
            f = self.view.frame;
            f.origin.x = 0.0;
            f.origin.y = 0.0;
            mHeadlineView.frame = f;
        };
        
        void (^headlineDoneAction)(BOOL finished) = ^(BOOL finished) {
            [prevHeadlineView removeFromSuperview];
        };
        
        if (animated) {
            [UIView animateWithDuration:0.5
                                  delay:0.0
                                options:UIViewAnimationCurveEaseOut|UIViewAnimationOptionAllowUserInteraction
                             animations:headlineAction
                             completion:headlineDoneAction];
        }
        else {
            headlineAction();
            headlineDoneAction(YES);
        }
    }
}


#pragma mark - Requests
- (void)requestMe {
    [[CSCloudSeeder sharedCSCloudSeeder] requestMe:^(id obj, NSError *error) {
        // Don't do anything if error
        if (!error) {
            [self requestMeActivities:YES];
        }
    }];    
}

- (void)requestMeActivities:(BOOL)isFromBeginning {
    NSString *cursor = nil;
    if (!isFromBeginning) {
        cursor = [[CSCloudSeeder sharedCSCloudSeeder] cursorForURL:SOUNDCLOUD_ME_ACTIVITIES_URL];
    }
    __block SCRequest *req =
    [[CSCloudSeeder sharedCSCloudSeeder] requestMeActivities:cursor
                                                       limit:kCSItemsPerRequest
                                                  completion:^(id obj, NSError *error) {
                                                      [mRequests removeObject:req];
                                                      if (!error) {
                                                          [self requestTracksForMeActivites];
                                                      }
                                                      else {
                                                          NSLog(@"request activities error");
                                                      }
                                                  }];
    [mRequests addObject:req];
    [self setIsLoading:YES];
}

- (void)requestTracksForMeActivites {
    __block SCRequest *req =
    [[CSCloudSeeder sharedCSCloudSeeder] requestTracksForMeActivites:^(id obj, NSError *error) {
        [mRequests removeObject:req];
        [self setIsLoading:NO];
        if (!error) {
            // Look for track comment
            for (NSDictionary *act in [CSCloudSeeder sharedCSCloudSeeder].activityList) {
                NSString *activityType = [act objectForKey:@"type"];
                if ([activityType isEqualToString:@"comment"]) {
                    NSString *username = [[[act objectForKey:@"origin"] objectForKey:@"user"] objectForKey:@"username"];
                    NSString *body = [[act objectForKey:@"origin"] objectForKey:@"body"];
                    
                    // Save
                    NSString *comment = [NSString stringWithFormat:@"%@ commented '%@' on your %@", username, body, kCSCustomTrackStr];
                    [self setHeadline:kCSHeadlineType_Comment data:CSLocalizedString(comment, nil)];
                    // Update UI
                    if (mHeadlineType == kCSHeadlineType_Comment) {
                        mHeadlineLabel.text = [self getHeadline:kCSHeadlineType_Comment];
                    }
                    break;
                }                    
            }

            // Look for track like
            for (NSDictionary *act in [CSCloudSeeder sharedCSCloudSeeder].activityList) {
                NSString *activityType = [act objectForKey:@"type"];
                if ([activityType isEqualToString:@"favoriting"]) {
                    NSString *username = [[[act objectForKey:@"origin"] objectForKey:@"user"] objectForKey:@"username"];
                    NSString *trackname = [[[act objectForKey:@"origin"] objectForKey:@"track"] objectForKey:@"title"];
                    
                    // Save
                    NSString *like = [NSString stringWithFormat:@"%@ liked your %@ '%@'", username, kCSCustomTrackStr, trackname];
                    [self setHeadline:kCSHeadlineType_Like data:CSLocalizedString(like, nil)];
                    // Update UI
                    if (mHeadlineType == kCSHeadlineType_Like) {
                        mHeadlineLabel.text = [self getHeadline:kCSHeadlineType_Like];
                    }
                    break;
                }                    
            }
        }
    }];
    [mRequests addObject:req];
}

- (void)requestLatestTrack {
    __block SCRequest *req =
    [[CSCloudSeeder sharedCSCloudSeeder] requestTrackList:kCSTrackList_Latest
                                                    limit:kCSItemsPerRequest
                                                   offset:0
                                               completion:^(id obj, NSError *error) {
                                                   [mRequests removeObject:req];
                                                   [self setIsLoading:NO];
                                                   
                                                   if (!error) {
                                                       NSArray *trackList = [[CSCloudSeeder sharedCSCloudSeeder].allTrackLists objectAtIndex:kCSTrackList_Latest];
                                                       if ([trackList count] > 0) {
                                                           CSTrack *track = [trackList objectAtIndex:0];
                                                           // Save
                                                           NSString *uploadedTrack = [NSString stringWithFormat:@"%@ uploaded %@ '%@'", track.username, kCSCustomTrackStr, track.title];                                                           
                                                           [self setHeadline:kCSHeadlineType_CloudSeederStatus
                                                                        data:CSLocalizedString(uploadedTrack, nil)];
                                                           // Update UI
                                                           if (mHeadlineType == kCSHeadlineType_CloudSeederStatus) {
                                                               mHeadlineLabel.text = [self getHeadline:kCSHeadlineType_CloudSeederStatus];
                                                           }
                                                       }
                                                   }
                                               }];
    [mRequests addObject:req];
}

- (void)requestNewsHeadline {
    __block AFHTTPRequestOperation *req =
    [[CSCloudSeeder sharedCSCloudSeeder] requestNewsHeadline:^(id obj, NSError *error) {
        [mRequests removeObject:req];
        [self setIsLoading:NO];
        
        if (!error) {
            NSLog(@"%@", obj);
            [self setHeadline:kCSHeadlineType_News data:obj];
            // Update UI
            if (mHeadlineType == kCSHeadlineType_News) {
                mHeadlineLabel.text = [self getHeadline:kCSHeadlineType_News];
            }
        }        
    }];
    [mRequests addObject:req];
}
@end
