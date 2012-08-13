//
//  UIViewController+CloudSeeder.m
//  CloudSeeder
//
//  Created by David Shu on 3/27/12.
//  Copyright (c) 2012 Retronyms. All rights reserved.
//

#import "UIViewController+CloudSeeder.h"

@implementation UIViewController (CloudSeeder)
- (void)presentModalViewController:(UIViewController *)modalViewController frame:(CGRect)frame animated:(BOOL)animated {
    modalViewController.modalPresentationStyle = UIModalPresentationPageSheet;
    [self presentModalViewController:modalViewController animated:YES];
    UIView *s = modalViewController.view.superview;
    s.frame = frame;
    // TODO: use a view's center instead of hardcode
    s.center = CGPointMake(1024/2.0, 768/2.0);    
}

@end
