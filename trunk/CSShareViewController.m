//
//  CSShareViewController.m
//  CloudSeeder
//
//  Created by David Shu on 4/30/12.
//  Copyright (c) 2012 Retronyms. All rights reserved.
//

#import "CSShareViewController.h"
#import "CSCloudSeeder.h"
#import "SCUI.h"

NSString * const kCSShareViewControllerWillShowNotification = @"kCSShareViewControllerWillShowNotification";

// Subclassed SoundCloud's sharing workflow classes so we can ensure our custom
// stuff happens, like adding bpm, adding to groups, etc.

@implementation CSRecordingSaveViewController
@synthesize metadata = mMetadata;

- (id)init {
    if (self = [super init]) {
        mMetadata = [[NSMutableDictionary alloc] initWithCapacity:1];
    }
    return self;
}

- (void)dealloc {
    [mMetadata release];
    
    [super dealloc];
}

- (void)setBPM:(int)aBPM {
    [mMetadata setObject:[NSString stringWithFormat:@"%d", aBPM] forKey:@"track[bpm]"];
}

- (void)setDescription:(NSString *)aDescription {
    [mMetadata setObject:aDescription forKey:@"track[description]"];
}

- (BOOL)hasMetadata {
    return ([mMetadata count] > 0);
}

@end


@implementation CSShareViewController
+ (SCShareViewController *)shareViewControllerWithFileURL:(NSURL *)aFileURL
                                        completionHandler:(SCSharingViewControllerComletionHandler)aCompletionHandler;
{
    CSRecordingSaveViewController *recView = [[[CSRecordingSaveViewController alloc] init] autorelease];
    if (!recView) return nil;
    
    [recView setFileURL:aFileURL];
    [recView setCompletionHandler:^(NSDictionary *trackInfo, NSError *error) {
        if (SC_CANCELED(error)) {
            NSLog(@"Canceled!");
        } else if (error) {
            NSLog(@"Ooops, something went wrong: %@", [error localizedDescription]);
        } else {
            // If you want to do something with the uploaded 
            // track this is the right place for that.
            NSLog(@"Uploaded track: %@", trackInfo);
            
            NSUInteger trackId = [[trackInfo objectForKey:@"id"] intValue];
            
            if ([recView hasMetadata]) {
                [[CSCloudSeeder sharedCSCloudSeeder] requestUpdateTrack:trackId
                                                               metadata:recView.metadata
                                                             completion:^(id obj, NSError *error) {
                                                             }];
            }
            
            // Add non-private tracks to groups
            if (![[trackInfo objectForKey:@"sharing"] isEqualToString:@"private"]) {
                // Add to my group and cloudseeder group
#ifdef SC_MY_GROUP_ID
                [[CSCloudSeeder sharedCSCloudSeeder] requestAddTrack:trackId
                                                             toGroup:kMyGroupId
                                                          completion:^(id obj, NSError *error) {
                                                          }];
#endif
                [[CSCloudSeeder sharedCSCloudSeeder] requestAddTrack:trackId
                                                             toGroup:CLOUDSEEDER_GROUP_ID
                                                          completion:^(id obj, NSError *error) {
                                                          }];
            }
        }
        
        if (aCompletionHandler) {
            aCompletionHandler(trackInfo, error);
        }
    }];
    
    CSShareViewController *shareViewController = [[CSShareViewController alloc] initWithRootViewController:recView];
    [shareViewController setModalPresentationStyle:UIModalPresentationFormSheet];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kCSShareViewControllerWillShowNotification
                                                        object:shareViewController];
    return [shareViewController autorelease];
}

// TODO: see if we can use the built in recordSaveController somehow?
- (CSRecordingSaveViewController *)recordingSaveController;
{
    return (CSRecordingSaveViewController *)self.topViewController;
}

- (void)setBPM:(NSUInteger)aBPM {
    [[self recordingSaveController] setBPM:aBPM];
}

- (void)setDescription:(NSString *)aDescription {
    [[self recordingSaveController] setDescription:aDescription];
}


@end
