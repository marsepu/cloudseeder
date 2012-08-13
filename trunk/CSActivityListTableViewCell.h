//
//  CSActivityListTableViewCell.h
//  CloudSeeder
//
//  Created by David Shu on 3/23/12.
//  Copyright (c) 2012 Retronyms. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kCSActivityListTableViewCellWidth (311.0)
#define kCSActivityListTableViewCellHeight (83.0)

@interface CSActivityListTableViewCell : UITableViewCell {
    // Data
    NSDictionary *mActivityDict;
    BOOL mIsComment;

    // UI
    IBOutlet UIImageView *mImageView;
    IBOutlet UILabel *mUserLabel;
    IBOutlet UILabel *mCommentLabel;
    IBOutlet UILabel *mDateLabel;
    IBOutlet UIImageView *mActivityIcon;
}
@property (nonatomic, readonly) UIImageView *imageView;
@property (nonatomic, readonly) NSDictionary *activityDict;

+ (CSActivityListTableViewCell *)create;
- (void)setup;
- (void)setActivityDict:(NSDictionary *)dict;

@end
