//
//  CSTrackListViewController.h
//  CloudSeeder
//
//  Created by David Shu on 3/23/12.
//  Copyright (c) 2012 Retronyms. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CSCloudSeeder.h"
#import "CSListViewController.h"

@class SCAudioStream;
@class CSTrackViewController;
@class CSMainViewController;
@class CSRefreshView;
@class CSTrack;
@interface CSTrackListViewController : CSListViewController <UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate> {
    // Track list
    CSTrackListType mTrackListType;
    NSUInteger mCurrentOffset;
    
    // Track Data
    CSTrack *mTrack;
    
    CSTrackViewController *mTrackViewController;
}
@property (nonatomic, assign) CSTrackListType trackListType;

- (void)refreshAnimated:(BOOL)animated;

@end