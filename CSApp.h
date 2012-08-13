//
//  CSApp.h
//  CloudSeeder
//
//  Created by David Shu on 7/30/12.
//  Copyright (c) 2012 Retronyms. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CSApp : NSObject {
    NSUInteger mAppId;
    NSString *mAppName;
    UIImage *mIconImage;
    NSString *mIconURL;
    NSString *mExternalURL;
    NSString *mPermalinkURL;
}
@property (nonatomic, assign) NSUInteger appId;
@property (nonatomic, copy) NSString *appName;
@property (nonatomic, retain) UIImage *iconImage;
@property (nonatomic, copy) NSString *externalURL;
@property (nonatomic, copy) NSString *permalinkURL;
@property (nonatomic, copy) NSString *iconURL;

- (id)initWithDict:(NSDictionary *)dict;
- (void)setDict:(NSDictionary *)dict;

@end