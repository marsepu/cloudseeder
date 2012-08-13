//
//  CSTrackListTableViewCell.m
//  CloudSeeder
//
//  Created by David Shu on 3/23/12.
//  Copyright (c) 2012 Retronyms. All rights reserved.
//

#import "CSTrackListTableViewCell.h"
#import "CSCloudSeeder.h"
#import "CSUser.h"
#import "CSTrack.h"

@implementation CSTrackListTableViewCell
@synthesize imageView = mImageView;
@synthesize track = mTrack;

+ (CSTrackListTableViewCell *)create {
	CSTrackListTableViewCell *cell = nil;
	NSArray *top_level = [[NSBundle mainBundle] loadNibNamed:@"CSTrackListTableViewCell" owner:self options:nil];
	for(id obj in top_level) {
		if([obj isKindOfClass:[CSTrackListTableViewCell class]]) {
			cell = (CSTrackListTableViewCell *) obj;
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

- (void)setup {
    mImageView.image = nil;    
}

- (void)prepareForReuse {
    [super prepareForReuse];
    mImageView.backgroundColor = [UIColor colorWithRed:204.0/255.0 green:204.0/255.0 blue:204.0/255.0 alpha:1.0];
    mImageView.image = nil;
    mTrack = nil;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)dealloc {
    // Release IBOutlets
    [mImageView release]; mImageView = nil;
    [mArtistLabel release]; mArtistLabel = nil;
    [mTrackLabel release]; mTrackLabel = nil;
    [mPlaysImage release]; mPlaysImage = nil;
    [mCommentsImage release]; mCommentsImage = nil;
    [mLikesImage release]; mLikesImage = nil;
    [mNumPlaysLabel release]; mNumPlaysLabel = nil;
    [mNumCommentsLabel release]; mNumCommentsLabel = nil;
    [mNumLikesLabel release]; mNumLikesLabel = nil;
    [mDateLabel release]; mDateLabel = nil;
    [mCloudSeederSelectLabel release]; mCloudSeederSelectLabel = nil;
    
    [super dealloc];
}

- (void)setTrack:(CSTrack *)aTrack {
    mTrack = aTrack;
    
    if (aTrack.isCloudSeederSelect) {
        // CloudSeeder select track
        mImageView.image = CSImage(@"cloudseeder-select-icon.png", nil);
        mImageView.backgroundColor = [UIColor clearColor];
        mImageView.bounds = CGRectMake(0, 0, mImageView.image.size.width, mImageView.image.size.height);
        CSUser *user = [[CSCloudSeeder sharedCSCloudSeeder] userForId:aTrack.userId];
        mArtistLabel.text = user.username;
        mTrackLabel.text = aTrack.title;
        NSString *dateAgo = [CSCloudSeeder dateAgoString:aTrack.createdAt];
        mDateLabel.text = CSLocalizedString(dateAgo, nil);
        
        mCloudSeederSelectLabel.hidden = NO;
        mCloudSeederSelectLabel.text = CSLocalizedString(@"CloudSeeder select", nil);
        
        mPlaysImage.hidden = YES;
        mNumPlaysLabel.hidden = YES;
        mCommentsImage.hidden = YES;
        mNumCommentsLabel.hidden = YES;
        mLikesImage.hidden = YES;
        mNumLikesLabel.hidden = YES;
        
        UIImageView *bgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"featured-row-bkg.png"]];
        self.backgroundView = bgView;
        [bgView release];
    }
    else {
        CSUser *user = [[CSCloudSeeder sharedCSCloudSeeder] userForId:aTrack.userId];
        if (user.avatarImage) {
            mImageView.image = user.avatarImage;
        }
        mImageView.bounds = CGRectMake(0, 0, 42, 42);
        mArtistLabel.text = user.username;
        
        mTrackLabel.text = aTrack.title;

        NSString *dateAgo = [CSCloudSeeder dateAgoString:aTrack.createdAt];
        mDateLabel.text = CSLocalizedString(dateAgo, nil);
        
        mNumPlaysLabel.text = [NSString stringWithFormat:@"%d", aTrack.playbackCount];
        mNumCommentsLabel.text = [NSString stringWithFormat:@"%d", aTrack.commentCount];
        mNumLikesLabel.text = [NSString stringWithFormat:@"%d", aTrack.favoritingsCount];
        
        mPlaysImage.image = CSImage(@"icn-play-primary-sm.png", kCSCustomPrimaryColor);
        mCommentsImage.image = CSImage(@"icn-comment-primary-sm.png", kCSCustomPrimaryColor);
        mLikesImage.image = CSImage(@"icn-like-primary-sm.png", kCSCustomPrimaryColor);
        mPlaysImage.hidden = NO;
        mNumPlaysLabel.hidden = NO;
        mCommentsImage.hidden = NO;
        mNumCommentsLabel.hidden = NO;
        mLikesImage.hidden = NO;
        mNumLikesLabel.hidden = NO;

        // Turn off cloudseeder select views
        mCloudSeederSelectLabel.hidden = YES;
        self.backgroundView = nil;
    }

    mImageView.center = CGPointMake(29, 41);
}

@end
