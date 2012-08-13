//
//  UIView+CloudSeeder.h
//  CloudSeeder
//
//  Created by David Shu on 3/31/12.
//  Copyright (c) 2012 Retronyms. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (CloudSeeder)
- (void)showFullScreen;
- (void)show:(BOOL)doShow animated:(BOOL)animated completion:(void (^)(BOOL finished))completion;
+ (UIView *)viewWithRotationTransform;
@end
