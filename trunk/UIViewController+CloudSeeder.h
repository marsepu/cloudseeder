//
//  UIViewController+CloudSeeder.h
//  CloudSeeder
//
//  Created by David Shu on 3/27/12.
//  Copyright (c) 2012 Retronyms. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (CloudSeeder)
- (void)presentModalViewController:(UIViewController *)modalViewController frame:(CGRect)frame animated:(BOOL)animated;
@end
