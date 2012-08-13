//
//  CSActivityListTableViewCell.m
//  CloudSeeder
//
//  Created by David Shu on 3/23/12.
//  Copyright (c) 2012 Retronyms. All rights reserved.
//

#import "CSActivityListTableViewCell.h"
#import "CSCloudSeeder.h"
#import "CSUser.h"

@implementation CSActivityListTableViewCell
@synthesize imageView = mImageView;
@synthesize activityDict = mActivityDict;

+ (CSActivityListTableViewCell *)create {
	CSActivityListTableViewCell *cell = nil;
	NSArray *top_level = [[NSBundle mainBundle] loadNibNamed:@"CSActivityListTableViewCell" owner:self options:nil];
	for(id obj in top_level) {
		if([obj isKindOfClass:[CSActivityListTableViewCell class]]) {
			cell = (CSActivityListTableViewCell *) obj;
            [cell retain];
            [cell setup];
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
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setup {
    mImageView.image = nil;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    mImageView.image = nil;
}

- (void)dealloc {
    // IBOutlets
    [mImageView release]; mImageView = nil;
    [mUserLabel release]; mUserLabel = nil;
    [mCommentLabel release]; mCommentLabel = nil;
    [mDateLabel release]; mDateLabel = nil;
    [mActivityIcon release]; mActivityIcon = nil;
    
    [super dealloc];
}

- (void)setActivityDict:(NSDictionary *)dict {
    NSString *activityType = [dict objectForKey:@"type"];
    NSDictionary *userDict = [[dict objectForKey:@"origin"] objectForKey:@"user"];
    
    // Set image
    CSUser *user = [[CSCloudSeeder sharedCSCloudSeeder] userForId:[[userDict objectForKey:@"id"] intValue]];
    if (user.avatarImage) {
        mImageView.image = user.avatarImage;
    }
    
    // Set date
    NSDate *createdDate = [CSCloudSeeder dateFromString:[dict objectForKey:@"created_at"]];
    NSString *dateAgo = [CSCloudSeeder dateAgoString:createdDate];
    mDateLabel.text = CSLocalizedString(dateAgo, nil);
    
    if ([activityType isEqualToString:@"comment"]) {
        mCommentLabel.hidden = NO;
        mCommentLabel.text = [[dict objectForKey:@"origin"] objectForKey:@"body"];
        mUserLabel.text = [userDict objectForKey:@"username"];
        
        mActivityIcon.image = CSImage(@"icn-comment-primary-lg.png", kCSCustomPrimaryColor);
    }
    else if ([activityType isEqualToString:@"favoriting"]) {
        mCommentLabel.hidden = YES;
        mUserLabel.text = [userDict objectForKey:@"username"];
        
        mActivityIcon.image = CSImage(@"icn-like-primary-lg.png", kCSCustomPrimaryColor);
    }
}
@end
