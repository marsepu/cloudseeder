//
//  CSApp.m
//  tabletop
//
//  Created by David Shu on 7/30/12.
//  Copyright (c) 2012 Retronyms. All rights reserved.
//

#import "CSApp.h"

@implementation CSApp
@synthesize appId = mAppId;
@synthesize appName = mAppName;
@synthesize iconImage = mIconImage;
@synthesize externalURL = mExternalURL;
@synthesize permalinkURL = mPermalinkURL;
@synthesize iconURL = mIconURL;

- (id)initWithDict:(NSDictionary *)dict {
    if (self = [super init]) {
        [self setDict:dict];
    }
    return self;
}

- (void)dealloc {
    self.appName = nil;
    self.iconImage = nil;
    self.externalURL = nil;
    self.permalinkURL = nil;
    self.iconURL = nil;
    [super dealloc];
}

- (void)setDict:(NSDictionary *)dict {
    self.appId = [[dict objectForKey:@"id"] intValue];
    self.appName = [dict objectForKey:@"name"];
    self.externalURL = [dict objectForKey:@"external_url"];
    self.permalinkURL = [dict objectForKey:@"permalink_url"];
    
    if ([dict objectForKey:@"icon_url"]) {
        self.iconURL = [dict objectForKey:@"icon_url"];
    }
}

@end
