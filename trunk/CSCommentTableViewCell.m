//
//  CSCommentTableViewCell.m
//  CloudSeeder
//
//  Created by David Shu on 3/23/12.
//  Copyright (c) 2012 Retronyms. All rights reserved.
//

#import "CSCommentTableViewCell.h"
#import "CSCloudSeeder.h"
#import "CSUser.h"

@implementation CSCommentTableViewCell
@synthesize imageView = mImageView;

+ (CSCommentTableViewCell *)create {
	CSCommentTableViewCell *cell = nil;
	NSArray *top_level = [[NSBundle mainBundle] loadNibNamed:@"CSCommentTableViewCell" owner:self options:nil];
	for(id obj in top_level) {
		if([obj isKindOfClass:[CSCommentTableViewCell class]]) {
			cell = (CSCommentTableViewCell *) obj;
            [cell retain];
			break;
		}
	}
	return cell;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    //[super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)dealloc {
    // IBOutlets
    [mTopRule release]; mTopRule = nil;
    [mBottomRule release]; mBottomRule = nil;
    [mImageView release]; mImageView = nil;
    [mUserLabel release]; mUserLabel = nil;
    [mCommentLabel release]; mCommentLabel = nil;
    [mDateLabel release]; mDateLabel = nil;
    [mActivityIcon release]; mActivityIcon = nil;
    
    [super dealloc];
}

- (void)setIsComment:(BOOL)isComment dict:(NSDictionary *)dict {
    mCommentDict = dict;
    mIsComment = isComment;

    CSUser *user;
    NSUInteger userId;
    if (isComment) {
        // Comments get a comment dictionary
        userId = [[[dict objectForKey:@"user"] objectForKey:@"id"] intValue];
        user = [[CSCloudSeeder sharedCSCloudSeeder] userForId:userId];
        mCommentLabel.hidden = NO;
        mCommentLabel.text = [dict objectForKey:@"body"];
        mUserLabel.text = user.username;
        
        // Set date
        NSDate *createdDate = [CSCloudSeeder dateFromString:[dict objectForKey:@"created_at"]];
        NSString *dateAgo = [CSCloudSeeder dateAgoString:createdDate];
        mDateLabel.text = CSLocalizedString(dateAgo, nil);
        
        mActivityIcon.image = CSImage(@"icn-comment-primary-sm.png", kCSCustomPrimaryColor);
    }
    else {
        // Likes get a user dictionary
        userId = [[dict objectForKey:@"id"] intValue];
        user = [[CSCloudSeeder sharedCSCloudSeeder] userForId:userId];
        mCommentLabel.hidden = YES;
        mUserLabel.text = user.username;
        mDateLabel.hidden = YES;
        
        mActivityIcon.image = CSImage(@"icn-like-primary-sm.png", kCSCustomPrimaryColor);
    }
    
    if (user.avatarImage) {
        mImageView.image = user.avatarImage;
    }
}

- (void)setCellPositionTypeForRow:(NSInteger)row totalCount:(NSInteger)totalCount {
    mCellPositionType = [self cellPositionTypeForRow:row totalCount:totalCount];

    if (mCellPositionType == kCSTableCell_Mid) {
        mTopRule.hidden = NO;
        mBottomRule.hidden = NO;
    }
    else if (mCellPositionType == kCSTableCell_Top || mCellPositionType == kCSTableCell_Bottom) {
        mTopRule.hidden = YES;
        mTopRule.hidden = YES;
    }
}


#pragma mark - Custom section view
// These header views work with the CSCommentTableViewCells
+ (UIView *)headerViewForSectionWithTitle:(NSString *)title {
    // Background
    UIView *bg = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 372.0, 22.0)] autorelease];
    bg.backgroundColor = [UIColor whiteColor];
    
    // Section title
    UILabel *l = [[[UILabel alloc] initWithFrame:CGRectInset(bg.frame, 15.0, 0)] autorelease];
    l.text = title;
    l.textColor = [UIColor grayColor];
    l.backgroundColor = [UIColor clearColor];
    l.font = [UIFont boldSystemFontOfSize:12.0];
    [bg addSubview:l];
    
    // Top rule image
    UIImage *ruleImage = [UIImage imageNamed:@"rule-grey.png"];
    UIImageView *topRule = [[[UIImageView alloc] initWithImage:ruleImage] autorelease];
    topRule.frame = CGRectMake(0.0, 0.0, 372.0, 1.0);
    UIImageView *bottomRule = [[[UIImageView alloc] initWithImage:ruleImage] autorelease];
    bottomRule.frame = CGRectMake(0.0, 22.0, 372.0, 1.0);
    
    [bg addSubview:topRule];
    [bg addSubview:bottomRule];
    
    return bg;
}
@end
