//
//  CSBundle.m
//  CloudSeeder
//
//  Created by David Shu on 4/11/12.
//  Copyright (c) 2012 Retronyms. All rights reserved.
//

#import "CSBundle.h"

#define kTrackName 

NSString * const kCSCustomTitleStr = kCSCustomAppStringValue;
NSString * const kCSCustomTrackStr = kCSCustomTrackStringValue;
NSString * const kCSCustomTrackPluralStr = kCSCustomTrackPluralStringValue;

NSString * const kCSControlString = @"kCSControlString";

@implementation CSBundle

+ (NSString *)string:(NSString *)str context:(NSString *)context {
    NSString *retStr = nil;
    if (context) {
        if ([context isEqualToString:kCSControlString]) {
            retStr = CSCustomControlCase(str);
        }
    }
    
    if (!retStr) {
        retStr = str;
    }
    
    return retStr;
}

+ (UIImage *)imageNamed:(NSString *)name withColor:(UIColor *)color {
//    NSBundle *bundle = [self bundle];
//    return [UIImage imageWithContentsOfFile:[bundle pathForResource:name ofType:@"png"]];
    return [UIImage imageNamed:name];
#if 0
    UIGraphicsBeginImageContextWithOptions(img.size, NO, [UIScreen mainScreen].scale);    
    CGContextRef context = UIGraphicsGetCurrentContext();
    [color setFill];
    CGContextTranslateCTM(context, 0, img.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextSetBlendMode(context, kCGBlendModeOverlay);
    CGRect rect = CGRectMake(0, 0, img.size.width, img.size.height);
    CGContextDrawImage(context, rect, img.CGImage);
    CGContextClipToMask(context, rect, img.CGImage);
    CGContextAddRect(context, rect);
    CGContextDrawPath(context,kCGPathFill);
    UIImage *coloredImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return coloredImg;
#endif
}
@end
