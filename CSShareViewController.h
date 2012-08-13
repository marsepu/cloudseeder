//
//  CSShareViewController.h
//  CloudSeeder
//
//  Created by David Shu on 4/30/12.
//  Copyright (c) 2012 Retronyms. All rights reserved.
//

#import "SCShareViewController.h"
#import "SCRecordingSaveViewController.h"

extern NSString * const kCSShareViewControllerWillShowNotification;

@interface CSRecordingSaveViewController : SCRecordingSaveViewController {
    NSMutableDictionary *mMetadata;
}
@property (nonatomic, readonly) NSMutableDictionary *metadata;

- (BOOL)hasMetadata;
- (void)setBPM:(int)aBPM;
- (void)setDescription:(NSString *)aDescription;
@end


@interface CSShareViewController : SCShareViewController

+ (CSShareViewController *)shareViewControllerWithFileURL:(NSURL *)aFileURL completionHandler:(SCSharingViewControllerComletionHandler)aCompletionHandler;
- (void)setBPM:(NSUInteger)aBPM;
- (void)setDescription:(NSString *)aDescription;
@end