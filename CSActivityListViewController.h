//
//  CSActivityListViewController.h
//  CloudSeeder
//
//  Created by David Shu on 3/23/12.
//  Copyright (c) 2012 Retronyms. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CSCloudSeeder.h"
#import "CSListViewController.h"

@class CSMainViewController;
@class CSTrackViewController;
@class CSRefreshView;
@class CSTrack;
@interface CSActivityListViewController : CSListViewController {
    CSTrack *mTrack;
    
    CSTrackViewController *mTrackViewController;
}

- (void)refreshAnimated:(BOOL)animated;

@end