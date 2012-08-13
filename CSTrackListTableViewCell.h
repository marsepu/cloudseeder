//
//  CSTrackListTableViewCell.h
//  CloudSeeder
//
//  Created by David Shu on 3/23/12.
//  Copyright (c) 2012 Retronyms. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kCSTrackListTableViewCellHeight (83.0)
#define kCSTrackListTableViewCellWidth (311.0)

@class CSTrack;
@interface CSTrackListTableViewCell : UITableViewCell {
    // Data
    CSTrack *mTrack;

    // UI
    IBOutlet UIImageView *mImageView;
    IBOutlet UILabel *mArtistLabel;
    IBOutlet UILabel *mTrackLabel;
    // Plays/comments/likes
    IBOutlet UIImageView *mPlaysImage;
    IBOutlet UIImageView *mCommentsImage;
    IBOutlet UIImageView *mLikesImage;
    IBOutlet UILabel *mNumPlaysLabel;
    IBOutlet UILabel *mNumCommentsLabel;
    IBOutlet UILabel *mNumLikesLabel;
    IBOutlet UILabel *mDateLabel;
    // CloudSeeder Select
    IBOutlet UILabel *mCloudSeederSelectLabel;
}
@property (nonatomic, readonly) UIImageView *imageView;
@property (nonatomic, readonly) CSTrack *track;

+ (CSTrackListTableViewCell *)create;
- (void)setup;
- (void)setTrack:(CSTrack *)aTrack;

@end
