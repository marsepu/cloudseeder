//
//  CSActivityListViewController.m
//  CloudSeeder
//
//  Created by David Shu on 3/23/12.
//  Copyright (c) 2012 Retronyms. All rights reserved.
//

#import "CSActivityListViewController.h"
#import "CSActivityListTableViewCell.h"
#import "CSMainViewController.h"
#import "UIView+CloudSeeder.h"
#import "CSTrackViewController.h"
#import "CSUser.h"
#import "CSTrack.h"
//#import "SCUI.h"
#import "UITableViewCell+CloudSeeder.h"

@interface CSActivityListViewController (Private)
- (void)requestMeActivities:(BOOL)isFromBeginning;
- (void)requestTracksForMeActivities;
- (void)requestImageForUser:(NSUInteger)userId;
@end

#pragma mark - CSActivityListViewController
@implementation CSActivityListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        mTrack = nil;
        // Custom initialization
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

    mTrackViewController = mCloudSeederController.trackViewController;

    mTableView.rowHeight = kCSActivityListTableViewCellHeight;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.view addSubview:mTrackViewController.view];
    mTrackViewController.view.frame = mDetailFrame;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}


#pragma mark - Public
- (void)refreshAnimated:(BOOL)animated {
    [self cancelRequests];
    
    mIsEndOfListReached = NO;
    [[CSCloudSeeder sharedCSCloudSeeder] removeCursorForURL:SOUNDCLOUD_ME_ACTIVITIES_URL];

    if ([[CSCloudSeeder sharedCSCloudSeeder] isAccountReady]) {
        // Remove needs login view no matter what if you're logged in
        [mCloudSeederController.needsLoginView show:NO
                                           animated:animated
                                         completion:^(BOOL finished) {
                                             [mCloudSeederController.needsLoginView removeFromSuperview];
                                         }];
        
        [self requestMeActivities:YES];
    }
    else {
        // User isn't logged in -- put up Needs Login blocker
        [self.view addSubview:mCloudSeederController.needsLoginView];
        mCloudSeederController.needsLoginView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
        [mCloudSeederController.needsLoginView show:YES
                                           animated:animated
                                         completion:nil];
    }
}


#pragma mark - Set/Get
- (NSArray *)currentList {
    return [CSCloudSeeder sharedCSCloudSeeder].activityList;
}


#pragma mark - Private
- (void)loadMoreTapped {
    [self refreshAnimated:YES];
}


#pragma mark - UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *ActListCellIdentifier = @"ActivityListCell";
    static NSString *CellIdentifier = @"Cell";
    
    if (indexPath.row < [self.currentList count]) {
        CSActivityListTableViewCell *cell = (CSActivityListTableViewCell *)[tableView dequeueReusableCellWithIdentifier:ActListCellIdentifier];
        if (cell == nil) {
            cell = [[CSActivityListTableViewCell create] autorelease];
        }
        NSDictionary *activityDict = [self.currentList objectAtIndex:indexPath.row];
        [cell setActivityDict:activityDict];
        if (!cell.imageView.image) {
            NSUInteger userId = [[[[activityDict objectForKey:@"origin"] objectForKey:@"user"] objectForKey:@"id"] intValue];
            [self requestImageForUser:userId];
        }
        return cell;
    }
    else {
        UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
            cell.frame = CGRectMake(0, 0, kCSActivityListTableViewCellWidth, kCSActivityListTableViewCellHeight);
            
            mLoadMoreButton = [self setupAsLoadMoreCell:cell];
            [mLoadMoreButton addTarget:self action:@selector(loadMoreTapped) forControlEvents:UIControlEventTouchUpInside];
        }
        return cell;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSUInteger count = [self.currentList count];
    // Show the load more cell
    if (!mIsEndOfListReached) {
        count++;
    }
    return count;
}


#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < [self.currentList count]) {
        NSUInteger trackId = [[[[[self.currentList objectAtIndex:indexPath.row]
                                 objectForKey:@"origin"]
                                objectForKey:@"track"]
                               objectForKey:@"id"] intValue];
        if (trackId == mTrack.trackId) {
            return;
        }
        
        mTrack = [[CSCloudSeeder sharedCSCloudSeeder].activityTrackList objectForKey:[NSString stringWithFormat:@"%d", trackId]];
        mTrackViewController.track = mTrack;
        [self.view addSubview:mTrackViewController.view];
        mTrackViewController.view.frame = mDetailFrame;
        [mTrackViewController refresh];
    }
}


#pragma mark - CloudSeeder Requests
- (void)requestMeActivities:(BOOL)isFromBeginning {
    NSString *cursor = nil;
    if (!isFromBeginning) {
        cursor = [[CSCloudSeeder sharedCSCloudSeeder] cursorForURL:SOUNDCLOUD_ME_ACTIVITIES_URL];
    }
    __block SCRequest *request =
    [[CSCloudSeeder sharedCSCloudSeeder] requestMeActivities:cursor
                                                       limit:kCSItemsPerRequest
                                                  completion:^(id obj, NSError *error) {                                                      
                                                      if (!error) {
                                                          // We've requested tracks that have activites, now figure out which tracks were made with our app
                                                          [self requestTracksForMeActivities];
                                                      }
                                                      else {
                                                          [mCloudSeederController showError:kCSError_NoNetwork];
                                                          NSLog(@"request activities error");
                                                      }
                                                  }];
    [mRequests addObject:request];
    [self setIsLoading:YES];
}

- (void)requestTracksForMeActivities {
    __block SCRequest *request =
    [[CSCloudSeeder sharedCSCloudSeeder] requestTracksForMeActivites:^(id obj, NSError *error) {
        [self setIsLoading:NO];
        if (!error) {
            if (![[CSCloudSeeder sharedCSCloudSeeder] cursorForURL:SOUNDCLOUD_ME_ACTIVITIES_URL]) {
                // No more data to request
                mIsEndOfListReached = YES;
            }
            
            if ([[CSCloudSeeder sharedCSCloudSeeder].activityList count] < kCSItemsPerRequest) {
                // We may get 0 tracks if the 10 tracks aren't made by my app
                if (!mIsEndOfListReached) {
                    [self requestMeActivities:NO];
                    return;
                }
            }
            
            [mTableView reloadData];                                                                  
        }
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
                                                   CSUser *u = (CSUser *)obj;
                                                   if (u && (u.avatarImage)) {
                                                       [mTableView reloadData];
                                                   }
                                               }];
    [mRequests addObject:request];
}

- (void)accountDidChange:(NSNotification *)notification {
    // Clear out previous user's data before refreshing
    [mTableView reloadData];
    [self refreshAnimated:YES];
}


@end
