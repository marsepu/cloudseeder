//
//  CSTrackListViewController.m
//  CloudSeeder
//
//  Created by David Shu on 3/23/12.
//  Copyright (c) 2012 Retronyms. All rights reserved.
//

#import "CSTrackListViewController.h"
#import "CSTrackListTableViewCell.h"
#import "CSTrackViewController.h"
#import "CSMainViewController.h"
#import "UIView+CloudSeeder.h"
#import "SCUI.h"
#import "UITableViewCell+CloudSeeder.h"
#import "CSUser.h"
#import "CSTrack.h"

@interface CSTrackListViewController (Private)
- (void)requestTrackList:(BOOL)isFromBeginning;
- (void)requestCloudSeederSelectTrack;
- (void)requestImageForUser:(NSUInteger)userId;
- (void)setIsLoading:(BOOL)aIsLoading;
- (void)showNeedsLogin:(BOOL)needsLogin animated:(BOOL)animated;
@end

#pragma mark - CSTrackListViewController
@implementation CSTrackListViewController
@synthesize trackListType = mTrackListType;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        mTrack = nil;
        
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
    
    mTableView.rowHeight = kCSTrackListTableViewCellHeight;
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


#pragma mark - Public
- (void)refreshAnimated:(BOOL)animated {
    [self cancelRequests];
    
    BOOL isLoggedIn = [[CSCloudSeeder sharedCSCloudSeeder] isAccountReady];
    
    if (mTrackListType == kCSTrackList_MyUploads) {
        [self showNeedsLogin:!isLoggedIn animated:animated];
        if (!isLoggedIn) {
            return;
        }
    }
    else if (mTrackListType == kCSTrackList_Following) {
        [mCloudSeederController.emptyMyUploadsView removeFromSuperview];
        [self showNeedsLogin:!isLoggedIn animated:animated];
        if (!isLoggedIn) {
            return;
        }
        
        [[CSCloudSeeder sharedCSCloudSeeder] removeCursorForURL:SOUNDCLOUD_FOLLOWING_URL];
    }
    else {
        [mCloudSeederController.needsLoginView removeFromSuperview];
        [mCloudSeederController.emptyMyUploadsView removeFromSuperview];
    }
    
    mCurrentOffset = 0;
    mIsEndOfListReached = NO;
    [self requestTrackList:YES];
    [self setIsLoading:YES];    
}


#pragma mark - Set/Get
- (NSArray *)currentList {
    return [[CSCloudSeeder sharedCSCloudSeeder].allTrackLists objectAtIndex:mTrackListType];
}


#pragma mark - Private
- (void)loadMoreTapped {
    [self requestTrackList:NO];
}

- (void)showNeedsLogin:(BOOL)needsLogin animated:(BOOL)animated {
    if (needsLogin) {
        [self.view addSubview:mCloudSeederController.needsLoginView];
        mCloudSeederController.needsLoginView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
        [mCloudSeederController.needsLoginView show:YES
                                           animated:animated
                                         completion:nil];
    }
    else {
        [mCloudSeederController.needsLoginView show:NO
                                           animated:animated
                                         completion:^(BOOL finished) {
                                             [mCloudSeederController.needsLoginView removeFromSuperview];
                                         }];
    }
}


#pragma mark - UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *TrackListCellIdentifier = @"TrackListCell";
    static NSString *CellIdentifier = @"Cell";

    if (indexPath.row < [self.currentList count]) {
        CSTrackListTableViewCell *cell = (CSTrackListTableViewCell *)[tableView dequeueReusableCellWithIdentifier:TrackListCellIdentifier];
        if (cell == nil) {
            cell = [[CSTrackListTableViewCell create] autorelease];
        }
        CSTrack *track = [self.currentList objectAtIndex:indexPath.row];

        [cell setTrack:track];
        if (!track.isCloudSeederSelect && !cell.imageView.image) {
            [self requestImageForUser:track.userId];
        }
        
        return cell;
    }
    else {
        UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
            cell.frame = CGRectMake(0, 0, kCSTrackListTableViewCellWidth, kCSTrackListTableViewCellHeight);
            
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
        // Show the selected track
        if ([self.currentList objectAtIndex:indexPath.row] == mTrack) {
            return;
        }
        
        mTrack = [self.currentList objectAtIndex:indexPath.row];
        mTrackViewController.track = mTrack;
        [self.view addSubview:mTrackViewController.view];
        mTrackViewController.view.frame = mDetailFrame;
        [mTrackViewController refresh];
    }
}


#pragma mark - CloudSeeder Requests
- (void)requestTrackList:(BOOL)isFromBeginning {
    if (mTrackListType == kCSTrackList_Following) {
        // Following track list uses the cursor style offset
        NSString *cursor = nil;
        if (!isFromBeginning) {
            cursor = [[CSCloudSeeder sharedCSCloudSeeder] cursorForURL:SOUNDCLOUD_FOLLOWING_URL];
        }
        __block SCRequest *request =
        [[CSCloudSeeder sharedCSCloudSeeder] requestTrackList:mTrackListType
                                                        limit:kCSItemsPerRequest
                                                       cursor:cursor
                                                   completion:^(id obj, NSError *error) {
                                                       [self setIsLoading:NO];

                                                       if (!error) {
                                                           if (![[CSCloudSeeder sharedCSCloudSeeder] cursorForURL:SOUNDCLOUD_FOLLOWING_URL]) {
                                                               mIsEndOfListReached = YES;
                                                           }
                                                           
                                                           [mTableView reloadData];
                                                       }
                                                       else {
                                                           [mCloudSeederController showError:kCSError_NoNetwork];
                                                       }
                                                   }];
        [mRequests addObject:request];
    }
    else {
        if (isFromBeginning) {
            mCurrentOffset = 0;
        }
        __block SCRequest *request =
        [[CSCloudSeeder sharedCSCloudSeeder] requestTrackList:mTrackListType
                                                        limit:kCSItemsPerRequest
                                                       offset:mCurrentOffset
                                                   completion:^(id obj, NSError *error) {
                                                       [self setIsLoading:NO];
                                                       
                                                       if (!error) {
                                                           NSUInteger numReceived = [obj intValue];
                                                           if (numReceived == 0) {
                                                               mIsEndOfListReached = YES;
                                                           }
                                                           
                                                           if (mTrackListType == kCSTrackList_MyUploads) {
                                                               if ([self.currentList count] == 0) {
                                                                   // Keep looking if my uploads
                                                                   // We may get 0 tracks if the latest 10 tracks aren't made by my app
                                                                   if (!mIsEndOfListReached) {
                                                                       [self requestTrackList:NO];
                                                                       return;
                                                                   }
                                                                   [self.view addSubview:mCloudSeederController.emptyMyUploadsView];
                                                                   mCloudSeederController.emptyMyUploadsView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
                                                                   [mCloudSeederController.emptyMyUploadsView show:YES animated:YES completion:nil];
                                                                   
                                                                   [mTableView reloadData];
                                                               }
                                                           }
                                                           else if (mTrackListType == kCSTrackList_Featured) {
                                                               if (kIsUsingCloudSeederSelect) {
                                                                   [self requestCloudSeederSelectTrack];
                                                               }
                                                               else {
                                                                   [mTableView reloadData];
                                                               }
                                                           }
                                                           else {
                                                               [mTableView reloadData];
                                                           }
                                                       }
                                                       else {
                                                           [mCloudSeederController showError:kCSError_NoNetwork];
                                                       }
                                                   }];
        [mRequests addObject:request];
    }
    mCurrentOffset += kCSItemsPerRequest;
    
    [self setIsLoading:YES];
}

- (void)requestCloudSeederSelectTrack {
    NSMutableArray *list = [[CSCloudSeeder sharedCSCloudSeeder].allTrackLists objectAtIndex:kCSTrackList_Featured];
    [[CSCloudSeeder sharedCSCloudSeeder] requestCloudSeederSelectTrackForList:list
                                                                   completion:^(id obj, NSError *error) {
                                                                       [mTableView reloadData];
                                                                   }];
}

- (void)requestImageForUser:(NSUInteger)userId {
    CSUser *user = [[CSCloudSeeder sharedCSCloudSeeder] userForId:userId];
    if (!user) {
        return;
    }

    // Make image request
    [[CSCloudSeeder sharedCSCloudSeeder] requestUserImage:user.avatarURL
                                                   userId:user.userId
                                                imageType:kCSImageURLType_badge
                                               completion:^(id obj, NSError *error) {
                                                   CSUser *u = (CSUser *)obj;
                                                   if (u && (u.avatarImage)) {
                                                       [mTableView reloadData];
                                                   }
                                               }];
}

- (void)accountDidChange:(NSNotification *)notification {
    [mTableView reloadData];
    [self refreshAnimated:YES];
}


@end
