//
//  CSTrack.h
//  CloudSeeder
//
//  Created by David Shu on 4/23/12.
//  Copyright (c) 2012 Retronyms. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CSTrack : NSObject {
    // Track
    NSUInteger mTrackId;
    NSString *mTitle;
    NSDate *mCreatedAt;
    NSString *mPermalinkURL;
    NSString *mArtworkURL;

    // Audio
    NSUInteger mDuration;
    NSString *mStreamURL;
    
    // User
    NSUInteger mUserId;
    NSString *mUsername;
    
    // Stats
    BOOL mIsUserFavorite;
    NSUInteger mPlaybackCount;
    NSUInteger mCommentCount;
    NSUInteger mFavoritingsCount;
    
    // Created with
    NSUInteger mCreatedWithId;

    BOOL mIsCloudSeederSelect;
}
@property (nonatomic, assign) NSUInteger trackId;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSDate *createdAt;
@property (nonatomic, copy) NSString *permalinkURL;
@property (nonatomic, copy) NSString *artworkURL;
// Created with
@property (nonatomic, assign) NSUInteger createdWithId;
// Audio
@property (nonatomic, assign) NSUInteger duration;
@property (nonatomic, copy) NSString *streamURL;
// User
@property (nonatomic, assign) NSUInteger userId;
@property (nonatomic, copy) NSString *username;
// Stats
@property (nonatomic, assign) BOOL isUserFavorite;
@property (nonatomic, assign) NSUInteger playbackCount;
@property (nonatomic, assign) NSUInteger commentCount;
@property (nonatomic, assign) NSUInteger favoritingsCount;
@property (nonatomic, assign) BOOL isCloudSeederSelect;

- (id)initWithDict:(NSDictionary *)dict;
- (void)setDict:(NSDictionary *)dict;

@end
