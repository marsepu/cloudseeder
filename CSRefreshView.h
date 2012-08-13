//
//  CSRefreshView.h
//  CloudSeeder
//
//  Created by David Shu on 4/10/12.
//  Copyright (c) 2012 Retronyms. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kCSRefreshHeight (65.0)

@interface CSRefreshView : UIView {
    IBOutlet UIImageView *mRefreshIcon;
}
@property (nonatomic, readonly) UIImageView *refreshIcon;
+ (CSRefreshView *)create;
@end
