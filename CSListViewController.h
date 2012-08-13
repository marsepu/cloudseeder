//
//  CSListViewController.h
//  CloudSeeder
//
//  Created by David Shu on 4/11/12.
//  Copyright (c) 2012 Retronyms. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CSMainViewController;
@class CSRefreshView;
@interface CSListViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate> {
    // Track list
    BOOL mIsEndOfListReached;
    IBOutlet UITableView *mTableView;
    BOOL mIsLoading;
    // Refresh
    CSRefreshView *mRefreshView;
    BOOL mIsAnimatingRefresh;
    // Load more
    UIButton *mLoadMoreButton;
    // Detail
    CGRect mDetailFrame;

    NSMutableArray *mRequests;
    CSMainViewController *mCloudSeederController;
}
@property (nonatomic, readonly, getter=currentList) NSArray *currentList;
@property (nonatomic, assign) CSMainViewController *cloudSeederController;

- (void)refreshAnimated:(BOOL)animated;
- (void)setIsLoading:(BOOL)aIsLoading;
- (UIButton *)setupAsLoadMoreCell:(UITableViewCell *)cell;
// Protected
- (void)cancelRequests;

@end
