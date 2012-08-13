//
//  CSUser.h
//  CloudSeeder
//
//  Created by David Shu on 3/27/12.
//  Copyright (c) 2012 Retronyms. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CSUser : NSObject {
    NSUInteger mUserId;
    NSString *mUsername;
    NSString *mAvatarURL;
    UIImage *mAvatarImage;
    NSString *mPermalinkURL;
}
@property (nonatomic, assign) NSUInteger userId;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *avatarURL;
@property (nonatomic, retain) UIImage *avatarImage;
@property (nonatomic, copy) NSString *permalinkURL;

- (id)initWithDict:(NSDictionary *)dict;
- (void)setDict:(NSDictionary *)dict;

@end