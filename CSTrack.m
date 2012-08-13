//
//  CSTrack.m
//  CloudSeeder
//
//  Created by David Shu on 4/23/12.
//  Copyright (c) 2012 Retronyms. All rights reserved.
//

#import "CSTrack.h"
#import "CSCloudSeeder.h"

@implementation CSTrack
@synthesize trackId = mTrackId;
@synthesize title = mTitle;
@synthesize createdAt = mCreatedAt;
@synthesize permalinkURL = mPermalinkURL;
@synthesize artworkURL = mArtworkURL;
@synthesize createdWithId = mCreatedWithId;
// Audio
@synthesize duration = mDuration;
@synthesize streamURL = mStreamURL;
// User
@synthesize userId = mUserId;
@synthesize username = mUsername;
// Stats
@synthesize isUserFavorite = mIsUserFavorite;
@synthesize playbackCount = mPlaybackCount;
@synthesize commentCount = mCommentCount;
@synthesize favoritingsCount = mFavoritingsCount;
@synthesize isCloudSeederSelect = mIsCloudSeederSelect;

- (id)initWithDict:(NSDictionary *)dict {
    if (self = [super init]) {
        [self setDict:dict];
    }
    return self;
}

- (void)dealloc {
    self.title = nil;
    self.createdAt = nil;
    self.permalinkURL = nil;
    self.artworkURL = nil;
    self.streamURL = nil;
    self.username = nil;
    
    [super dealloc];
}

- (void)setDict:(NSDictionary *)dict {
    // Activities provide mini track descriptions with a slightly different dictionary
    BOOL isMiniTrack = NO;
    if ([dict count] < 10) {
        isMiniTrack = YES;
    }
    
    // Found in both mini-track and track descriptions
    // Track
    self.trackId = [[dict objectForKey:@"id"] intValue];
    self.title = [dict objectForKey:@"title"];
    self.permalinkURL = [dict objectForKey:@"permalink_url"];
    
    // Stream
    self.streamURL = [dict objectForKey:@"stream_url"];

    if (!isMiniTrack) {
        // Track
        self.createdAt = [CSCloudSeeder dateFromString:[dict objectForKey:@"created_at"]];
        id artwork = [dict objectForKey:@"artwork_url"];
        if ([artwork isKindOfClass:[NSString class]]) {
            self.artworkURL = artwork;
        }
        
        // Stream
        self.duration = [[dict objectForKey:@"duration"] intValue];
        
        // User
        self.userId = [[[dict objectForKey:@"user"] objectForKey:@"id"] intValue];
        self.username = [[dict objectForKey:@"user"] objectForKey:@"username"];
        
        // Stats
        self.isUserFavorite = [[dict objectForKey:@"user_favorite"] boolValue];
        self.playbackCount = [[dict objectForKey:@"playback_count"] intValue];
        self.commentCount = [[dict objectForKey:@"comment_count"] intValue];
        self.favoritingsCount = [[dict objectForKey:@"favoritings_count"] intValue];

        // Created with
        self.createdWithId = [[[dict objectForKey:@"created_with"] objectForKey:@"id"] intValue];
    }
    else {        
        // User
        self.userId = [[dict objectForKey:@"user_id"] intValue];        
    }
}

@end
