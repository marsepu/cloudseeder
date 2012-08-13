//
//  CSListViewController.m
//  CloudSeeder
//
//  Created by David Shu on 4/11/12.
//  Copyright (c) 2012 Retronyms. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "CSListViewController.h"
#import "CSRefreshView.h"
#import "CSMainViewController.h"

@interface CSListViewController ()

@end

@implementation CSListViewController
@synthesize currentList;
@synthesize cloudSeederController = mCloudSeederController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        mLoadMoreButton = nil;
        mRequests = [[NSMutableArray alloc] initWithCapacity:5];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    mDetailFrame = self.view.frame;
    mDetailFrame.origin.x = mTableView.frame.size.width;
    mDetailFrame.origin.y = mTableView.frame.origin.y;
    mDetailFrame.size.height = mTableView.frame.size.height;
    mDetailFrame.size.width -= mTableView.frame.size.width;
    
    // Pull to refresh view
    mRefreshView = [[CSRefreshView create] autorelease];
    CGRect f = mRefreshView.frame;
    f.origin.y = -mRefreshView.frame.size.height;
    mRefreshView.frame = f;
    [mTableView addSubview:mRefreshView];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    
    [mTableView release]; mTableView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

- (void)dealloc {
    [mRequests release];

    // IBOutlets
    [mTableView release]; mTableView = nil;
    
    [super dealloc];
}


#pragma mark - Public
- (void)refreshAnimated:(BOOL)animated {
}

- (void)setIsLoading:(BOOL)aIsLoading {
    // Show spinner view
    [mCloudSeederController showSpinner:aIsLoading animated:YES];
    mIsLoading = aIsLoading;
    
    if (mLoadMoreButton) {
        mLoadMoreButton.selected = aIsLoading;
    }
    
    if (!aIsLoading) {
        [UIView animateWithDuration:0.3
                              delay:0.0
                            options:0
                         animations:^{
                             mTableView.contentInset = UIEdgeInsetsZero;
                         }
                         completion:nil];
    }
}


#pragma mark - Protected
- (void)cancelRequests {
    [[CSCloudSeeder sharedCSCloudSeeder] cancelRequests:mRequests];
    [mRequests removeAllObjects];
}


#pragma mark - Pull to Refresh
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    // Pull to refresh
    if (mIsLoading) {
        return;
    }
    
    CGFloat rowHeight = kCSRefreshHeight;
    if (scrollView.contentOffset.y <= -rowHeight) {
        CABasicAnimation *spin = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
        spin.duration = 0.5;
        spin.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        spin.toValue = [NSNumber numberWithFloat:-M_PI*2];
        [mRefreshView.refreshIcon.layer addAnimation:spin forKey:@"spinAnimation"];

        [UIView animateWithDuration:0.5
                              delay:0.0
                            options:UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             scrollView.contentInset = UIEdgeInsetsMake(rowHeight, 0, 0, 0);
                         }
                         completion:^(BOOL finished) {
                             mIsAnimatingRefresh = NO;
                         }];

        [self refreshAnimated:NO];
    }    
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (mIsLoading || mIsAnimatingRefresh) {
        return;
    }
    
    CGFloat rowHeight = kCSRefreshHeight;
    if (scrollView.isDragging && scrollView.contentOffset.y <= -rowHeight) {
        mIsAnimatingRefresh = YES;

        CABasicAnimation *spin = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
        spin.duration = 0.5;
        spin.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        spin.toValue = [NSNumber numberWithFloat:M_PI*2];
        [mRefreshView.refreshIcon.layer addAnimation:spin forKey:@"spinAnimation"];
    }
}


#pragma mark - UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return -1;
}

- (UIButton *)setupAsLoadMoreCell:(UITableViewCell *)cell {
    UIButton *loadMoreButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *image = CSImage(@"btn-primary-lg.png", kCSCustomPrimaryColor);
    loadMoreButton.frame = CGRectMake(0, 0, image.size.width, image.size.height);
    [loadMoreButton setBackgroundImage:image forState:UIControlStateNormal];
    loadMoreButton.titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:12.0];
    loadMoreButton.titleLabel.textColor = [UIColor whiteColor];
    loadMoreButton.titleLabel.shadowColor = [UIColor blackColor];
    loadMoreButton.titleLabel.shadowOffset = CGSizeMake(0.0, -1.0);
    [loadMoreButton setTitle:CSLocalizedString(@"Load more", kCSControlString) forState:UIControlStateNormal];
    [loadMoreButton setTitle:CSLocalizedString(@"Loading", kCSControlString) forState:UIControlStateSelected];
    
    [cell addSubview:loadMoreButton];
    loadMoreButton.center = cell.center;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return loadMoreButton;
}

@end
