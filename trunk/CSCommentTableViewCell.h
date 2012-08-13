//
//  CSCommentTableViewCell.h
//  CloudSeeder
//
//  Created by David Shu on 3/23/12.
//  Copyright (c) 2012 Retronyms. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITableViewCell+CloudSeeder.h"

#define kCSCommentTableViewCellHeight (70.0)

@interface CSCommentTableViewCell : UITableViewCell {
    // Data
    NSDictionary *mCommentDict;
    BOOL mIsComment;

    // UI
    CSTableCellPositionType mCellPositionType;
    IBOutlet UIImageView *mTopRule;
    IBOutlet UIImageView *mBottomRule;    
    IBOutlet UIImageView *mImageView;
    IBOutlet UILabel *mUserLabel;
    IBOutlet UILabel *mCommentLabel;
    IBOutlet UILabel *mDateLabel;
    IBOutlet UIImageView *mActivityIcon;
}
@property (nonatomic, readonly) UIImageView *imageView;

+ (CSCommentTableViewCell *)create;
+ (UIView *)headerViewForSectionWithTitle:(NSString *)title;
- (void)setIsComment:(BOOL)isComment dict:(NSDictionary *)dict;
- (void)setCellPositionTypeForRow:(NSInteger)row totalCount:(NSInteger)totalCount;

@end
