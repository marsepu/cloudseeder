//
//  UIView+CloudSeeder.m
//  CloudSeeder
//
//  Created by David Shu on 3/31/12.
//  Copyright (c) 2012 Retronyms. All rights reserved.
//

#import "UIView+CloudSeeder.h"

@implementation UIView (CloudSeeder)
- (void)showFullScreen {
    UIView *parentView = [[UIApplication sharedApplication] keyWindow];
    UIView *viewWithTransform = [[parentView subviews] objectAtIndex:0];
    
    self.frame = CGRectMake(0, 0, 1024, 768);
    self.transform = viewWithTransform.transform;
    // Transform may change origin
    CGRect f = self.frame;
    f.origin.x = 0;
    f.origin.y = 0;
    self.frame = f;
    [parentView addSubview:self];
}

- (void)show:(BOOL)doShow animated:(BOOL)animated completion:(void (^)(BOOL finished))completion {
    void (^showAction)(void) = ^{
        if (doShow) {
            self.alpha = 1.0;
        }
        else {
            self.alpha = 0.0;
        }
    };
    
    if (animated) {
        [UIView animateWithDuration:0.3
                              delay:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:showAction
                         completion:completion];
    }
    else {
        showAction();
        if (completion) {
            completion(YES);
        }
    }
}

+ (UIView *)viewWithRotationTransform {
    UIWindow* window = [UIApplication sharedApplication].keyWindow;
    UIView *viewWithTransform = [[window subviews] objectAtIndex:0];
    
    UIView *v = [[[UIView alloc] initWithFrame:viewWithTransform.frame] autorelease];
    v.transform = viewWithTransform.transform;
    CGRect f = v.frame;
    f.origin.x = 0.0f;
    f.origin.y = 0.0f;
    v.frame = f;
    
    return v;
}


@end
