//
//  CSUser.m
//  CloudSeeder
//
//  Created by David Shu on 3/27/12.
//  Copyright (c) 2012 Retronyms. All rights reserved.
//

#import "CSUser.h"
#import "SCRequest.h"
#import "SCSoundCloud.h"
#import "CSCloudSeeder.h"

@implementation CSUser
@synthesize userId = mUserId;
@synthesize avatarURL = mAvatarURL;
@synthesize avatarImage = mAvatarImage;
@synthesize username = mUsername;
@synthesize permalinkURL = mPermalinkURL;

- (id)initWithDict:(NSDictionary *)dict {
    if (self = [super init]) {
        [self setDict:dict];
    }
    return self;
}

- (void)dealloc {
    self.avatarURL = nil;
    self.username = nil;
    self.avatarImage = nil;
    self.permalinkURL = nil;
    [super dealloc];
}

- (void)setDict:(NSDictionary *)dict {
    self.userId = [[dict objectForKey:@"id"] intValue];
    self.username = [dict objectForKey:@"username"];
    self.avatarURL = [dict objectForKey:@"avatar_url"];
    self.permalinkURL = [dict objectForKey:@"permalink_url"];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"CSUser %d %@", self.userId, self.username];
}

@end
