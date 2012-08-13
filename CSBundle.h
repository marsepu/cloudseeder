//
//  CSBundle.h
//  CloudSeeder
//
//  Created by David Shu on 4/11/12.
//  Copyright (c) 2012 Retronyms. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSCloudSeederConfig.h"

#ifdef CLOUDSEEDER_LIGHT_THEME
    #define kCSCustomAccountBGImage             @"profile-bkg-light.png"
    #define kCSCustomToolbarStyle               UIBarStyleDefault
    #define kCSCustomSidebarBG                  [UIColor colorWithRed:229.0/255.0 green:232.0/255.0 blue:240.0/255.0 alpha:1.0]
    #define kCSCustomSidebarTitleText           [UIColor colorWithRed:51.0/255.0 green:51.0/255.0 blue:51.0/255.0 alpha:1.0]
    #define kCSCustomSidebarTitleTextShadow     [UIColor whiteColor]
    #define kCSCustomSidebarSelectedText        [UIColor whiteColor]
    #define kCSCustomSidebarSelectedTextShadow  [UIColor blackColor]
    #define kCSCustomSidebarText                [UIColor colorWithRed:102.0/255.0 green:102.0/255.0 blue:102.0/255.0 alpha:1.0]
    #define kCSCustomTableSeparatorColor        [UIColor whiteColor]
#else   // CLOUDSEEDER_DARK_THEME (default)
    #define kCSCustomAccountBGImage             @"profile-bkg-dark.png"
    #define kCSCustomToolbarStyle               UIBarStyleBlack
    #define kCSCustomSidebarBG                  [UIColor blackColor]
    #define kCSCustomSidebarTitleText           [UIColor whiteColor]
    #define kCSCustomSidebarTitleTextShadow     [UIColor blackColor]
    #define kCSCustomSidebarSelectedText        [UIColor whiteColor]
    #define kCSCustomSidebarSelectedTextShadow  [UIColor blackColor]
    #define kCSCustomSidebarText                [UIColor whiteColor]
//    #define kCSCustomTableSeparatorColor        [UIColor colorWithRed:224.0/255.0 green:224.0/255.0 blue:224.0/255.0 alpha:1.0]
    #define kCSCustomTableSeparatorColor        [UIColor lightGrayColor]
#endif

#define CLOUDSEEDER_GROUP_ID                (77276)

// String literals
extern NSString * const kCSCustomTitleStr;
extern NSString * const kCSCustomTrackStr;
extern NSString * const kCSCustomTrackPluralStr;

// String context
extern NSString * const kCSControlString;

//#define CSLocalizedString(key, comment) [[CSBundle bundle] localizedStringForKey:key value:key table:nil]
#define CSLocalizedString(key, comment) [CSBundle string:key context:comment]
#define CSImage(imageName, color) [CSBundle imageNamed:(imageName) withColor:(color)]

@interface CSBundle : NSObject
+ (NSString *)string:(NSString *)str context:(NSString *)context;
//+ (UIImage *)imageNamed:(NSString *)name context:(NSString *)context;
+ (UIImage *)imageNamed:(NSString *)name withColor:(UIColor *)color;
@end
