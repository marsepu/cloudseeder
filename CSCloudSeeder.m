//
//  CSCloudSeeder.m
//  CloudSeeder
//
//  Created by David Shu on 3/23/12.
//  Copyright (c) 2012 Retronyms. All rights reserved.
//

#import "CSCloudSeeder.h"
#import "SCUI.h"
#import "JSONKit.h"
#import "AFHTTPRequestOperation.h"
#import "CSUser.h"
#import "CSTrack.h"
#import "CSApp.h"

#define TRACK_LIST_CAPACITY (20)
#define USER_LIST_CAPACITY  (30)

NSString * const kCSMyAccountDidChangeNotification = @"kCSMyAccountDidChangeNotification";
NSString * const kCSMyAccountActivityNotification = @"kCSMyAccountActivityNotification";
NSString * const kCSnext_href = @"next_href";

NSString * const kCSImageURLTypeStrings[] = {
    @"t500x500",
    @"crop",
    @"t300x300",
    @"large",
    @"t67x67",
    @"badge",
    @"small",
    @"tiny",
    @"mini",
    @"original",
};

// Get the compiler to complain if these aren't filled out correctly
const BOOL kIsUsingCloudSeederSelect = CS_USE_CLOUDSEEDER_SELECT;
const NSUInteger kMyAppId = SC_MY_APP_ID;
const NSUInteger kMyFeaturedUserId = SC_MY_FEATURED_USER_ID;
const NSUInteger kMyGroupId = SC_MY_GROUP_ID;

@interface CSCloudSeeder (Private)
- (void)clearAccountData;
+ (NSString *)getQueryValue:(NSString *)queryField fromURLString:(NSString *)urlStr;
- (CSUser *)getOrCreateUserForDict:(NSDictionary *)userDict;
- (BOOL)handleNextCursorForURL:(NSString *)requestURL URLStringToProcess:(NSString *)URLStringToProcess;
- (void)addRequest:(id)request;
- (void)removeRequest:(id)request;
+ (NSString *)setImageType:(CSImageURLType)imageType forURLString:(NSString *)urlStr;
@end

@implementation CSCloudSeeder
@synthesize allTrackLists = mAllTrackLists;
@synthesize commentsList = mCommentsList;
@synthesize likesList = mLikesList;
@synthesize myAccount = mMyAccount;
@synthesize activityList = mActivityList;
@synthesize activityTrackList = mActivityTrackList;
@synthesize userList = mUserList;
@synthesize appList = mAppList;

#pragma mark - Singleton
static CSCloudSeeder *sharedCSCloudSeederPtr = nil;

+ (CSCloudSeeder *)sharedCSCloudSeeder {
    @synchronized(self) {
        if (sharedCSCloudSeederPtr == nil) {
            [[self alloc] init]; // assignment not done here
		}
    }
    return sharedCSCloudSeederPtr;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (sharedCSCloudSeederPtr == nil) {
            sharedCSCloudSeederPtr = [super allocWithZone:zone];
            return sharedCSCloudSeederPtr;  // assignment and return on first allocation
        }
    }
    return nil; //on subsequent allocation attempts return nil
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}


#pragma mark - CloudSeeder Data
// Clears all CloudSeeder data except for requests
// Call cancelAllRequests to clear out requests
- (void)clearAllData {
    for (int i = 0; i < kCSTrackList_Count; i++) {
        [[mAllTrackLists objectAtIndex:i] removeAllObjects];
    }
    
    [mCommentsList removeAllObjects];
    [mLikesList removeAllObjects];
    [mUserList removeAllObjects];
    [mAppList removeAllObjects];
    
    [self clearAccountData];
}

// Clears data associated with your account
- (void)clearAccountData {
    [mMyAccount removeAllObjects];
    [mShareConnections removeAllObjects];
    [mActivityList removeAllObjects];
    [mActivityTrackList removeAllObjects];
    [[mAllTrackLists objectAtIndex:kCSTrackList_MyUploads] removeAllObjects];
    [[mAllTrackLists objectAtIndex:kCSTrackList_Following] removeAllObjects];
    [mCursors removeAllObjects];
}


#pragma mark - SoundCloud API Helpers
- (NSString *)URLString:(NSString *)url {
    if (![self isAccountReady]) {
        url = [NSString stringWithFormat:@"%@?client_id=%@", url, SC_MY_CLIENT_ID];
    }
    return url;
}

static NSDateFormatter *sDateFormatter;
+ (NSDate *)dateFromString:(NSString *)dateStr {
    return [sDateFormatter dateFromString:dateStr];    
}

+ (NSString *)dateAgoString:(NSDate *)date {
    NSString *ret = nil;
    unsigned int unitFlags = NSHourCalendarUnit | NSMinuteCalendarUnit | NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit;
    
    NSDateComponents *comps = [[NSCalendar currentCalendar] components:unitFlags fromDate:date toDate:[NSDate date] options:0];
    
    // Year
    if ([comps year] == 1) {
        ret = [NSString stringWithFormat:@"%d year", [comps year]];
    }
    else if ([comps year] > 1){
        ret = [NSString stringWithFormat:@"%d years", [comps year]];
    }
    // Month
    else if ([comps month] == 1) {
        ret = [NSString stringWithFormat:@"%d month", [comps month]];
    }
    else if ([comps month] > 1) {
        ret = [NSString stringWithFormat:@"%d months", [comps month]];
    }
    // Day
    else if ([comps day] == 1) {
        ret = [NSString stringWithFormat:@"%d day", [comps day]];
    }
    else if ([comps day] > 1) {
        ret = [NSString stringWithFormat:@"%d days", [comps day]];
    }
    // Hour
    else if ([comps hour] == 1) {
        ret = [NSString stringWithFormat:@"%d hour", [comps hour]];
    }
    else if ([comps hour] > 1) {
        ret = [NSString stringWithFormat:@"%d hours", [comps hour]];
    }
    // Minute
    else if ([comps minute] == 1) {
        ret = [NSString stringWithFormat:@"%d minute", [comps minute]];
    }
    else if ([comps minute] > 1) {
        ret = [NSString stringWithFormat:@"%d minutes", [comps minute]];
    }
    else {
        ret = @"Just now";
    }
    
    return ret;
}

+ (BOOL)isTrackCreatedWithApp:(NSDictionary *)trackDict {
    NSDictionary *createdWith = [trackDict objectForKey:@"created_with"];
    if (createdWith) {
        if ([[createdWith objectForKey:@"id"] intValue] == kMyAppId) {
            return YES;
        }
    }
    return NO;
}

+ (NSString *)setImageType:(CSImageURLType)imageType forURLString:(NSString *)urlStr {
    NSString *typeStr = [NSString stringWithFormat:@"-%@.jpg", kCSImageURLTypeStrings[imageType]];
    
    return [urlStr stringByReplacingOccurrencesOfString:@"-large.jpg" withString:typeStr];
}


#pragma mark Cursors
- (NSString *)cursorForURL:(NSString *)urlStr {
    return [mCursors objectForKey:urlStr];
}

- (void)removeCursorForURL:(NSString *)urlStr {
    [mCursors removeObjectForKey:urlStr];
}

- (BOOL)handleNextCursorForURL:(NSString *)requestURL URLStringToProcess:(NSString *)URLStringToProcess {
    BOOL wasCursorSet = NO;
    NSString *cursorValue = [CSCloudSeeder getQueryValue:@"cursor" fromURLString:URLStringToProcess];
    
    NSString *prevCursor = [mCursors objectForKey:requestURL];
    if (cursorValue && !(prevCursor && [prevCursor isEqualToString:cursorValue])) {
        [mCursors setObject:cursorValue forKey:requestURL];
        wasCursorSet = YES;
    }
    else {
        [self removeCursorForURL:requestURL];
    }
    
    return wasCursorSet;
}


#pragma mark - My Account
- (BOOL)isAccountReady {
    return ([SCSoundCloud account]!=nil);
}

- (void)logoutAccount {
    [SCSoundCloud removeAccess];
}

- (NSArray *)idsForShareConnection:(CSShareType)shareType {
    NSMutableArray *shares = [NSMutableArray arrayWithCapacity:2];
    NSString *serviceName = nil;
    if (shareType == kCSShare_Facebook) {
        serviceName = @"facebook_profile";
    }
    else if (shareType == kCSShare_Twitter) {
        serviceName = @"twitter";
    }
    else if (shareType == kCSShare_Tumblr) {
        serviceName = @"tumblr";
    }
    
    for (NSDictionary *sd in mShareConnections) {
        if ([[sd objectForKey:@"service"] isEqualToString:serviceName]) {
            [shares addObject:[[sd objectForKey:@"id"] stringValue]];
        }
    }
    
    return shares;
}


#pragma mark - User
- (NSString *)userIdKey:(NSUInteger)userId {
    return [NSString stringWithFormat:@"%d", userId];
}

- (CSUser *)userForId:(NSUInteger)userId {
    NSString *userKey = [self userIdKey:userId];
    return [mUserList objectForKey:userKey];
}

- (CSUser *)getOrCreateUserForDict:(NSDictionary *)userDict {
    NSString *userKey = [self userIdKey:[[userDict objectForKey:@"id"] intValue]];
    CSUser *user = [mUserList objectForKey:userKey];
    if (!user) {
        user = [[CSUser alloc] initWithDict:userDict];
        [mUserList setObject:user forKey:userKey];
        [user release];
    }
    return user;    
}


#pragma mark - Requests
// Requests my account data and sends out an account did change notification
// results: my account data, nil if error
- (SCRequest *)requestMe:(CSResponseHandler)completion {
    __block SCRequest *req =
    [SCRequest performMethod:SCRequestMethodGET
                  onResource:[NSURL URLWithString:SOUNDCLOUD_ME_URL]
             usingParameters:nil
                 withAccount:[SCSoundCloud account]
      sendingProgressHandler:nil
             responseHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                 [self removeRequest:req];
                 id results = nil;
                 NSError *jsonError = nil;
                 if (data) {
                     id parsedData = [data objectFromJSONDataWithParseOptions:JKParseOptionStrict error:&jsonError];
                     if (parsedData) {
                         [mMyAccount removeAllObjects];
                         [mMyAccount addEntriesFromDictionary:parsedData];
                         [self getOrCreateUserForDict:parsedData];
                         
                         // Notify that user account is ready
                         [[NSNotificationCenter defaultCenter] postNotificationName:kCSMyAccountDidChangeNotification object:self];
                         
                         results = mMyAccount;
                     }                     
                 }
                 
                 if (!error) { error = jsonError; }
                 completion(results, error);
             }];
    [self addRequest:req];
    return req;
}

// Requests a refresh for my account data, doesn't send any notification
// results: my account data, nil if error
- (SCRequest *)requestMeUpdate:(CSResponseHandler)completion {
    __block SCRequest *req =
    [SCRequest performMethod:SCRequestMethodGET
                  onResource:[NSURL URLWithString:SOUNDCLOUD_ME_URL]
             usingParameters:nil
                 withAccount:[SCSoundCloud account]
      sendingProgressHandler:nil
             responseHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                 [self removeRequest:req];
                 id results = nil;
                 NSError *jsonError = nil;
                 if (data) {
                     id parsedData = [data objectFromJSONDataWithParseOptions:JKParseOptionStrict error:&jsonError];
                     if (parsedData) {
                         [mMyAccount removeAllObjects];
                         [mMyAccount addEntriesFromDictionary:parsedData];
                         [self getOrCreateUserForDict:parsedData];
                         
                         results = mMyAccount;
                     }                     
                 }
                 
                 if (!error) { error = jsonError; }
                 completion(results, error);
             }];
    [self addRequest:req];
    return req;
}

// Request available sharing connections to facebook, twitter, etc.
// results: share connection array, nil if error
- (SCRequest *)requestMeConnections:(CSResponseHandler)completion {
    __block SCRequest *req =
    [SCRequest performMethod:SCRequestMethodGET
                  onResource:[NSURL URLWithString:SOUNDCLOUD_ME_CONNECTIONS_URL]
             usingParameters:nil
                 withAccount:[SCSoundCloud account]
      sendingProgressHandler:nil
             responseHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                 [self removeRequest:req];
                 id results = nil;
                 NSError *jsonError = nil;
                 if (data) {
                     id parsedData = [data objectFromJSONDataWithParseOptions:JKParseOptionStrict error:&jsonError];
                     if (parsedData) {
                         [mShareConnections removeAllObjects];
                         [mShareConnections addObjectsFromArray:results];
                         NSLog(@"%@", mShareConnections);
                         results = mShareConnections;
                     }                     
                 }
                 
                 if (!error) { error = jsonError; }
                 completion(results, error);
             }];
    [self addRequest:req];
    return req;    
}

// Request latest activities
// results: always nil
- (SCRequest *)requestMeActivities:(NSString *)cursor limit:(NSUInteger)limit completion:(CSResponseHandler)completion {
    BOOL isBeginningOfList = NO;
    if (!cursor) {
        isBeginningOfList = YES;
    }

    // Build params
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   [NSString stringWithFormat:@"%d", limit], @"limit",
                                   nil];
    if (cursor) {
        [params setObject:cursor forKey:@"cursor"];
    }

    __block SCRequest *req =
    [SCRequest performMethod:SCRequestMethodGET
                  onResource:[NSURL URLWithString:SOUNDCLOUD_ME_ACTIVITIES_URL]
             usingParameters:params
                 withAccount:[SCSoundCloud account]
      sendingProgressHandler:nil
             responseHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                 [self removeRequest:req];
                 id results = nil;
                 NSError *jsonError = nil;
                 if (data) {
                     id parsedData = [data objectFromJSONDataWithParseOptions:JKParseOptionStrict error:&jsonError];
                     if (parsedData) {
                         if (isBeginningOfList) {
                             [mActivityList removeAllObjects];
                             [mActivityTrackList removeAllObjects];
                         }

                         [self handleNextCursorForURL:SOUNDCLOUD_ME_ACTIVITIES_URL URLStringToProcess:[parsedData objectForKey:kCSnext_href]];
                         
                         for (NSDictionary *act in [parsedData objectForKey:@"collection"]) {
                             NSString *activityType = [act objectForKey:@"type"];
                             if ([activityType isEqualToString:@"comment"] || [activityType isEqualToString:@"favoriting"]) {
                                 // We only want comments and likes
                                 [mActivityList addObject:act];

                                 // Limit list size
                                 if ([mActivityList count] > TRACK_LIST_CAPACITY) {
                                     [mActivityList removeObjectAtIndex:0];
                                 }

                                 // Keep track of this user
                                 [self getOrCreateUserForDict:[[act objectForKey:@"origin"] objectForKey:@"user"]];                                 
                             }
                         }
                     }                     
                 }

                 if (!error) { error = jsonError; }
                 completion(results, error);
             }];
    [self addRequest:req];
    return req;
}

// Call this after requestMeActivities to filter out tracks not made by your app
// results: list of tracks related to activities, nil if error
- (SCRequest *)requestTracksForMeActivites:(CSResponseHandler)completion {
     // Gather track Id's
    NSMutableArray *trackIds = [NSMutableArray arrayWithCapacity:[mActivityList count]];
    for (NSDictionary *act in mActivityList) {
        [trackIds addObject:[[[[act objectForKey:@"origin"] objectForKey:@"track"] objectForKey:@"id"] stringValue]];
    }

    return [self requestTracksWithIds:trackIds completion:^(id obj, NSError *error) {
        id results = nil;
        if (!error) {
            NSMutableDictionary *trackList = [NSMutableDictionary dictionaryWithCapacity:[obj count]];
            // Add to track list (map of trackId => trackDict's)
            for (CSTrack *track in obj) {
                [trackList setObject:track forKey:[NSString stringWithFormat:@"%d", track.trackId]];
            }
            
            // Filter out activities on tracks not created with our app
            NSMutableArray *toRemove = [NSMutableArray arrayWithCapacity:[mActivityList count]];
            for (NSDictionary *act in mActivityList) {
                NSString *actTrackId = [[[[act objectForKey:@"origin"] objectForKey:@"track"] objectForKey:@"id"] stringValue];
                if (![trackList objectForKey:actTrackId]) {
                    [toRemove addObject:act];
                }
            }
            [mActivityList removeObjectsInArray:toRemove];
            
            // Add these tracks to the list
            [mActivityTrackList addEntriesFromDictionary:trackList];
            results = mActivityTrackList;
        }
        completion(results, error); 
    }];
}

// Request to follow or unfollow a user
// results: doFollow, or nil if error
- (SCRequest *)requestFollow:(BOOL)doFollow user:(NSUInteger)userId completion:(CSResponseHandler)completion {
    NSString *urlStr = [NSString stringWithFormat:@"%@/me/followings/%d.json", SOUNDCLOUD_BASE_URL, userId];

    SCRequestMethod method = SCRequestMethodPUT;
    if (!doFollow) {
        method = SCRequestMethodDELETE;
    }
    
    __block SCRequest *req =
    [SCRequest performMethod:method
                  onResource:[NSURL URLWithString:urlStr]
             usingParameters:nil
                 withAccount:[SCSoundCloud account]
      sendingProgressHandler:nil
             responseHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                 [self removeRequest:req];
                 id results = nil;
                 
                 if (!error) {
                     results = [NSNumber numberWithBool:doFollow];
                     [[NSNotificationCenter defaultCenter] postNotificationName:kCSMyAccountActivityNotification object:self];
                 }
                 completion(results, error);
             }];
    [self addRequest:req];
    return req;
}

// Request to favorite or unfavorite a track
// results: isLike, or nil if error
- (SCRequest *)requestFavorite:(BOOL)isFavorite track:(NSUInteger)trackId completion:(CSResponseHandler)completion {
    NSString *urlStr = [NSString stringWithFormat:@"%@/me/favorites/%d.json", SOUNDCLOUD_BASE_URL, trackId];
    
    SCRequestMethod method = SCRequestMethodPUT;
    if (!isFavorite) {
        method = SCRequestMethodDELETE;
    }
    
    __block SCRequest *req =
    [SCRequest performMethod:method
                  onResource:[NSURL URLWithString:urlStr]
             usingParameters:nil
                 withAccount:[SCSoundCloud account]
      sendingProgressHandler:nil
             responseHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                 [self removeRequest:req];
                 id results = nil;
                 NSError *jsonError = nil;
                 if (data) {
                     id parsedData = [data objectFromJSONDataWithParseOptions:JKParseOptionStrict error:&jsonError];
                     if (parsedData) {
                         BOOL isLike = NO;
                         if ([[parsedData objectForKey:@"status"] isEqualToString:@"201 - Created"]) {
                             NSLog(@"like track (%d) OK", trackId);
                             isLike = YES;
                         }
                         results = [NSNumber numberWithBool:isLike];
                         [[NSNotificationCenter defaultCenter] postNotificationName:kCSMyAccountActivityNotification object:self];
                     }                     
                 }
                 
                 if (!error) { error = jsonError; }
                 completion(results, error);
             }];
    [self addRequest:req];
    return req;
}

// Request to comment on a track
// results: YES if successful, or nil if error
- (SCRequest *)requestComment:(NSString *)comment track:(NSUInteger)trackId completion:(CSResponseHandler)completion {
    NSString *urlStr = [NSString stringWithFormat:@"%@/tracks/%d/comments.json", SOUNDCLOUD_BASE_URL, trackId];
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            comment, @"comment[body]",
                            nil];
    
    __block SCRequest *req =
    [SCRequest performMethod:SCRequestMethodPOST
                  onResource:[NSURL URLWithString:urlStr]
             usingParameters:params
                 withAccount:[SCSoundCloud account]
      sendingProgressHandler:nil
             responseHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                 [self removeRequest:req];
                 id results = nil;
                 NSError *jsonError = nil;
                 if (data) {
                     id parsedData = [data objectFromJSONDataWithParseOptions:JKParseOptionStrict error:&jsonError];
                     if (parsedData) {
                         NSUInteger commentTrackId = [[parsedData objectForKey:@"track_id"] intValue];
                         NSUInteger commentUserId = [[parsedData objectForKey:@"user_id"] intValue];
                         NSString *commentBody = [parsedData objectForKey:@"body"];
                         NSUInteger myUserId = [[mMyAccount objectForKey:@"id"] intValue];
                         if (commentTrackId==trackId && commentUserId==myUserId && [commentBody isEqualToString:comment]) {
                             NSLog(@"comment OK");
                             results = [NSNumber numberWithBool:YES];
                         }
                     }
                     
                 }
                 
                 if (!error) { error = jsonError; }                 
                 completion(results, error);
             }];
    [self addRequest:req];
    return req;
}

// Request to share a track on the given connections
// results: YES if successful, or nil if error
- (SCRequest *)requestShareTrack:(NSUInteger)trackId withNote:(NSString *)note onConnections:(NSArray *)connections completion:(CSResponseHandler)completion {
    NSString *urlStr = [NSString stringWithFormat:@"%@/tracks/%d/shared-to/connections", SOUNDCLOUD_BASE_URL, trackId];

    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            connections, @"connections[][id]",
                            note, @"sharing_note",
                            nil];
    
    __block SCRequest *req =
    [SCRequest performMethod:SCRequestMethodPOST
                  onResource:[NSURL URLWithString:urlStr]
             usingParameters:params
                 withAccount:[SCSoundCloud account]
      sendingProgressHandler:nil
             responseHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                 [self removeRequest:req];
                 id results = nil;
                 NSError *jsonError = nil;
                 if (data) {
                     id parsedData = [data objectFromJSONDataWithParseOptions:JKParseOptionStrict error:&jsonError];
                     if (parsedData) {
                         NSLog(@"requestShareTrack %@, error = %@", parsedData, error);
                         results = [NSNumber numberWithBool:YES];
                     }
                 }
                 
                 if (!error) { error = jsonError; }
                 completion(results, error);
             }];
    [self addRequest:req];
    return req;
}

// Am I following this user?
// results: doesFollow, nil if error
- (SCRequest *)requestIsFollowingUser:(NSUInteger)otherUserId completion:(CSResponseHandler)completion {
    NSString *urlStr = [NSString stringWithFormat:@"%@/me/followings/%d.json", SOUNDCLOUD_BASE_URL, otherUserId];
    
    __block SCRequest *req =
    [SCRequest performMethod:SCRequestMethodGET
                  onResource:[NSURL URLWithString:urlStr]
             usingParameters:nil
                 withAccount:[SCSoundCloud account]
      sendingProgressHandler:nil
             responseHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                 [self removeRequest:req];
                 id results = nil;
                 if (data) {
                     NSError *jsonError = nil;
                     id parsedData = [data objectFromJSONDataWithParseOptions:JKParseOptionStrict error:&jsonError];
                     
                     BOOL doesFollow = NO;                     
                     if (parsedData == nil) {
                         doesFollow = YES;
                     }
                     results = [NSNumber numberWithBool:doesFollow];
                 }
                 completion(results, error);
             }];
    [self addRequest:req];
    return req;
}

// Request to add a track to a group
// results: YES if added, or nil if error
- (SCRequest *)requestAddTrack:(NSInteger)trackId toGroup:(NSInteger)groupId completion:(CSResponseHandler)completion {
    NSString *urlStr = [NSString stringWithFormat:@"%@/groups/%d/contributions/%d", SOUNDCLOUD_BASE_URL, groupId, trackId];
    
    __block SCRequest *req =
    [SCRequest performMethod:SCRequestMethodPUT
                  onResource:[NSURL URLWithString:urlStr]
             usingParameters:nil
                 withAccount:[SCSoundCloud account]
      sendingProgressHandler:nil
             responseHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                 [self removeRequest:req];
                 id results = nil;
                 if (!error) {
                     results = [NSNumber numberWithBool:YES];
                 }
                 
                 completion(results, error);
             }];
    [self addRequest:req];
    return req;
}

// Request to update a track's metadata
- (SCRequest *)requestUpdateTrack:(NSInteger)trackId metadata:(NSDictionary *)metadata completion:(CSResponseHandler)completion {
    NSString *urlStr = [NSString stringWithFormat:@"%@/tracks/%d.json", SOUNDCLOUD_BASE_URL, trackId];

    __block SCRequest *req =
    [SCRequest performMethod:SCRequestMethodPUT
                  onResource:[NSURL URLWithString:urlStr]
             usingParameters:metadata
                 withAccount:[SCSoundCloud account]
      sendingProgressHandler:nil
             responseHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                 [self removeRequest:req];
                 id results = nil;
                 NSError *jsonError = nil;
                 if (data) {
                     id parsedData = [data objectFromJSONDataWithParseOptions:JKParseOptionStrict error:&jsonError];
                     
                     results = parsedData;
                 }
                 
                 if (!error) { error = jsonError; }                 
                 completion(results, error);
             }];
    [self addRequest:req];
    return req;    
}

// Requests all the comments for a given track
// results: list of comments, or nil if error
- (SCRequest *)requestTrackComments:(NSUInteger)trackId completion:(CSResponseHandler)completion {
    NSString *urlStr = [NSString stringWithFormat:@"%@/tracks/%d/comments.json", SOUNDCLOUD_BASE_URL, trackId];
    
    NSDictionary *params = nil;
    if (![self isAccountReady]) {
        params = [NSDictionary dictionaryWithObjectsAndKeys:SC_MY_CLIENT_ID, @"client_id", nil];
    }
    
    __block SCRequest *req =
    [SCRequest performMethod:SCRequestMethodGET
                  onResource:[NSURL URLWithString:urlStr]
             usingParameters:params
                 withAccount:[SCSoundCloud account]
      sendingProgressHandler:nil
             responseHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                 [self removeRequest:req];
                 id results = nil;
                 NSError *jsonError = nil;
                 if (data) {
                     id parsedData = [data objectFromJSONDataWithParseOptions:JKParseOptionStrict error:&jsonError];
                     
                     [mCommentsList removeAllObjects];
                     
                     for (NSDictionary *commentDict in parsedData) {
                         [self getOrCreateUserForDict:[commentDict objectForKey:@"user"]];
                         [mCommentsList addObject:commentDict];
                     }
                     results = mCommentsList;
                 }
                 
                 if (!error) { error = jsonError; }                 
                 completion(results, error);
             }];
    [self addRequest:req];
    return req;
}

// Requests all the favorites (likes) for a given track
// results: list of favorites, or nil if error
- (SCRequest *)requestTrackFavoriters:(NSUInteger)trackId completion:(CSResponseHandler)completion {
    NSString *urlStr = [NSString stringWithFormat:@"%@/tracks/%d/favoriters.json", SOUNDCLOUD_BASE_URL, trackId];
    
    NSDictionary *params = nil;
    if (![self isAccountReady]) {
        params = [NSDictionary dictionaryWithObjectsAndKeys:SC_MY_CLIENT_ID, @"client_id", nil];
    }
    
    __block SCRequest *req =
    [SCRequest performMethod:SCRequestMethodGET
                  onResource:[NSURL URLWithString:urlStr]
             usingParameters:params
                 withAccount:[SCSoundCloud account]
      sendingProgressHandler:nil
             responseHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                 [self removeRequest:req];
                 id results = nil;
                 NSError *jsonError = nil;
                 if (data) {
                     id parsedData = [data objectFromJSONDataWithParseOptions:JKParseOptionStrict error:&jsonError];
                     
                     [mLikesList removeAllObjects];
                     
                     for (NSDictionary *userDict in parsedData) {
                         [self getOrCreateUserForDict:userDict];
                         [mLikesList addObject:userDict];
                     }
                 }
                 
                 if (!error) { error = jsonError; }                 
                 completion(results, error);
             }];
    [self addRequest:req];
    return req;
}

// Requests track data for every track given
// results: list of tracks, or nil if error
- (SCRequest *)requestTracksWithIds:(NSArray *)trackIds completion:(CSResponseHandler)completion {
    NSString *urlStr = [NSString stringWithFormat:@"%@/tracks.json", SOUNDCLOUD_BASE_URL];

    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   [trackIds componentsJoinedByString:@", "], @"ids",
                                   nil];
    if (![self isAccountReady]) {
        [params setObject:SC_MY_CLIENT_ID forKey:@"client_id"];
    }
    
    __block SCRequest *req =
    [SCRequest performMethod:SCRequestMethodGET
                  onResource:[NSURL URLWithString:urlStr]
             usingParameters:params
                 withAccount:[SCSoundCloud account]
      sendingProgressHandler:nil
             responseHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                 [self removeRequest:req];
                 id results = nil;
                 NSError *jsonError = nil;
                 if (data) {
                     id parsedData = [data objectFromJSONDataWithParseOptions:JKParseOptionStrict error:&jsonError];
                     
                     NSMutableArray *list = [NSMutableArray arrayWithCapacity:[parsedData count]];
                     // Filter out tracks not made with my app
                     for (NSDictionary *trackDict in parsedData) {
                         if ([CSCloudSeeder isTrackCreatedWithApp:trackDict]) {
                             // Add track
                             CSTrack *track = [[CSTrack alloc] initWithDict:trackDict];
                             [list addObject:track];
                             [track release];
                             
                             // Add user
                             [self getOrCreateUserForDict:[trackDict objectForKey:@"user"]];
                         }
                     }
                     results = list;
                 }
                 
                 if (!error) { error = jsonError; }
                 completion(results, error);
             }];
    [self addRequest:req];
    return req;
}

// Requests the CloudSeeder Select track and inserts it into "list"
// results: cloudseeder select track, or nil if error
- (AFHTTPRequestOperation *)requestCloudSeederSelectTrackForList:(NSMutableArray *)list completion:(CSResponseHandler)completion {
    NSString *urlStr = [NSString stringWithFormat:CLOUDSEEDER_SELECT_URL, kMyAppId];
    NSURLRequest *urlReq = [NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
    AFHTTPRequestOperation *req = [[[AFHTTPRequestOperation alloc] initWithRequest:urlReq] autorelease];
    [req setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id data) {
        [self removeRequest:req];
        id results = nil;
        NSError *jsonError = nil;
        if (data) {
            id parsedData = [data objectFromJSONDataWithParseOptions:JKParseOptionStrict error:&jsonError];
            // Remove previous CloudSeeder Select track
            CSTrack *toRemove = nil;
            for (CSTrack *track in list) {
                if (track.isCloudSeederSelect) {
                    toRemove = track;
                    break;
                }
            }
            if (toRemove) {
                [list removeObject:toRemove];
            }
            
            // Return now if no track returned from server
            if ([parsedData count] <= 0) {
                completion(nil, nil);
                return;
            }
            
            NSDictionary *trackDict = parsedData;
            
            // Add track
            CSTrack *selectTrack = [[CSTrack alloc] initWithDict:trackDict];
            selectTrack.isCloudSeederSelect = YES;
            // Save the app that made this track
            CSApp *app = [[CSApp alloc] initWithDict:[trackDict objectForKey:@"created_with"]];
            [mAppList setObject:app forKey:[NSNumber numberWithInt:app.appId]];
            [app release];
            
            // Insert into the given list by createdAt date
            NSInteger i = 0;
            for (CSTrack *t in list) {
                if ([selectTrack.createdAt timeIntervalSinceDate:t.createdAt] > 0) {
                    i--;
                    if (i < 0) {
                        i = 0;
                    }
                    break;
                }
                i++;
            }
            [list insertObject:selectTrack atIndex:i];
            [selectTrack release];
            
            // Add user
            [self getOrCreateUserForDict:[trackDict objectForKey:@"user"]];
            
            results = trackDict;
        }
        
        completion(results, jsonError);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self removeRequest:req];
        completion(nil, error);
    }];
    [self addRequest:req];
    [req start];
    return req;
}

/*
- (SCRequest *)requestApp:(NSUInteger)appId completion:(CSResponseHandler)completion {
    NSString *urlStr = [NSString stringWithFormat:@"%@/apps/%d.json", SOUNDCLOUD_BASE_URL, appId];
    
    NSDictionary *params = nil;
    if (![self isAccountReady]) {
        params = [NSDictionary dictionaryWithObjectsAndKeys:SC_MY_CLIENT_ID, @"client_id", nil];
    }
    
    __block SCRequest *req =
    [SCRequest performMethod:SCRequestMethodGET
                  onResource:[NSURL URLWithString:urlStr]
             usingParameters:params
                 withAccount:[SCSoundCloud account]
      sendingProgressHandler:nil
             responseHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                 [self removeRequest:req];
                 id results = nil;
                 NSError *jsonError = nil;
                 if (data) {
                     id parsedData = [data objectFromJSONDataWithParseOptions:JKParseOptionStrict error:&jsonError];
                     
                     results = parsedData;
                     
                     if (!error) { error = jsonError; }
                     completion(results, error);
                 }
             }];
    [self addRequest:req];
    return req;
}
*/

// Request track lists that use the limit+offset style requests
// results: number just received, or nil if error
- (SCRequest *)requestTrackList:(CSTrackListType)listType limit:(NSUInteger)limit offset:(NSUInteger)offset completion:(CSResponseHandler)completion {
    NSString *urlStr;
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   [NSString stringWithFormat:@"%d", limit], @"limit",
                                   [NSString stringWithFormat:@"%d", offset], @"offset",
                                   nil];
    
    if (listType == kCSTrackList_Featured) {
        urlStr = SOUNDCLOUD_FEATURED_URL;
    }
    else if (listType == kCSTrackList_Popular) {
        urlStr = SOUNDCLOUD_APP_TRACKS_URL;
        [params setObject:@"hotness" forKey:@"order"];
    }
    else if (listType == kCSTrackList_Latest) {
        urlStr = SOUNDCLOUD_APP_TRACKS_URL;
        
        [params setObject:@"created_at" forKey:@"order"];
    }
    else if (listType == kCSTrackList_MyUploads) {
        NSUInteger userId = [[[CSCloudSeeder sharedCSCloudSeeder].myAccount objectForKey:@"id"] intValue];
        urlStr = [NSString stringWithFormat:@"%@/users/%d/tracks.json", SOUNDCLOUD_BASE_URL, userId];
    }
    else {
        NSAssert(0, @"invalid track list value");
    }
    
    if (![self isAccountReady]) {
        [params setObject:SC_MY_CLIENT_ID forKey:@"client_id"];
    }
    
    __block SCRequest *req =
    [SCRequest performMethod:SCRequestMethodGET
                  onResource:[NSURL URLWithString:urlStr]
             usingParameters:params
                 withAccount:[SCSoundCloud account]
      sendingProgressHandler:nil
             responseHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                 [self removeRequest:req];
                 id results = nil;
                 NSError *jsonError = nil;
                 if (data) {
                     id parsedData = [data objectFromJSONDataWithParseOptions:JKParseOptionStrict error:&jsonError];
                     
                     NSMutableArray *list = [mAllTrackLists objectAtIndex:listType];
                     
                     // Requested start of list, clear
                     if (offset == 0) {
                         [list removeAllObjects];
                     }
                     
                     // Filter out tracks not made with my app
                     for (NSDictionary *trackDict in parsedData) {
                         if ([CSCloudSeeder isTrackCreatedWithApp:trackDict]) {
                             // Add track
                             CSTrack *track = [[CSTrack alloc] initWithDict:trackDict];
                             [list addObject:track];
                             [track release];

                             // Limit list size
                             if ([list count] > TRACK_LIST_CAPACITY) {
                                 [list removeObjectAtIndex:0];
                             }
                             
                             // Add user
                             [self getOrCreateUserForDict:[trackDict objectForKey:@"user"]];
                         }
                     }
                     results = [NSNumber numberWithInt:[parsedData count]];
                 }
                 
                 if (!error) { error = jsonError; }
                 completion(results, error);
             }];
    [self addRequest:req];
    return req;
}

// Request tracks that use the limit+cursor style requests
- (SCRequest *)requestTrackList:(CSTrackListType)listType limit:(NSUInteger)limit cursor:(NSString *)cursor completion:(CSResponseHandler)completion {
    // Build URL
    NSString *urlStr;
    if (listType == kCSTrackList_Following) {
        urlStr = SOUNDCLOUD_FOLLOWING_URL;
    }

    // Build params
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   [NSString stringWithFormat:@"%d", limit], @"limit",
                                   nil];
    if (![self isAccountReady]) {
        [params setObject:SC_MY_CLIENT_ID forKey:@"client_id"];
    }
    if (cursor) {
        [params setObject:cursor forKey:@"cursor"];
    }
    
    __block SCRequest *req =
    [SCRequest performMethod:SCRequestMethodGET
                  onResource:[NSURL URLWithString:urlStr]
             usingParameters:params
                 withAccount:[SCSoundCloud account]
      sendingProgressHandler:nil
             responseHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                 [self removeRequest:req];
                 id results = nil;
                 NSError *jsonError = nil;
                 if (data) {
                     id parsedData = [data objectFromJSONDataWithParseOptions:JKParseOptionStrict error:&jsonError];
                     
                     NSMutableArray *list = [mAllTrackLists objectAtIndex:listType];
                     
                     // Requested start of list, clear
                     if (!cursor) {
                         [list removeAllObjects];
                     }

                     if ([self handleNextCursorForURL:urlStr URLStringToProcess:[parsedData objectForKey:kCSnext_href]]) {                     
                         // Do some things specific to Following lists
                         if (listType == kCSTrackList_Following) {
                             NSMutableArray *tracks = [NSMutableArray arrayWithCapacity:[parsedData count]];
                             for (NSDictionary *act in [parsedData objectForKey:@"collection"]) {
                                 [tracks addObject:[act objectForKey:@"origin"]];
                             }
                             parsedData = tracks;
                         }
                         
                         // Filter out tracks not made by my app
                         for (NSDictionary *trackDict in parsedData) {
                             if ([CSCloudSeeder isTrackCreatedWithApp:trackDict]) {
                                 // Add track
                                 CSTrack *track = [[CSTrack alloc] initWithDict:trackDict];
                                 [list addObject:track];
                                 [track release];

                                 // Limit list size
                                 if ([list count] > TRACK_LIST_CAPACITY) {
                                     [list removeObjectAtIndex:0];
                                 }

                                 // Add user                                 
                                 [self getOrCreateUserForDict:[trackDict objectForKey:@"user"]];
                             }
                         }
                         
                         results = [NSNumber numberWithInt:[parsedData count]];
                     }
                 }
                 
                 if (!error) { error = jsonError; }
                 completion(results, error);
             }];
    [self addRequest:req];
    return req;
}

// Requests a user image
// result: user with image, or nil if error
- (SCRequest *)requestUserImage:(NSString *)urlStr userId:(NSUInteger)userId imageType:(CSImageURLType)imageType completion:(CSResponseHandler)completion {
    // Do we already have this image?
    CSUser *user = [mUserList objectForKey:[self userIdKey:userId]];
    if (user && user.avatarImage) {
        completion(user, nil);
        return nil;
    }
    
    urlStr = [CSCloudSeeder setImageType:imageType forURLString:urlStr];

    __block SCRequest *req =
    [SCRequest performMethod:SCRequestMethodGET
                  onResource:[NSURL URLWithString:urlStr]
             usingParameters:nil
                 withAccount:nil
      sendingProgressHandler:nil
             responseHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                 [self removeRequest:req];
                 id result = nil;
                 if (!error) {
                     CSUser *user = [mUserList objectForKey:[self userIdKey:userId]];
                     if (user) {
                         user.avatarImage = [UIImage imageWithData:data];
                         result = user;
                     }
                 }
                 completion(result, error);
             }];
    [self addRequest:req];
    return req;
}

// Requests album art for a track
// results: UIImage of track art, or nil if error
- (SCRequest *)requestTrackImage:(NSString *)urlStr trackId:(NSUInteger)trackId imageType:(CSImageURLType)imageType completion:(CSResponseHandler)completion {
    urlStr = [CSCloudSeeder setImageType:imageType forURLString:urlStr];
    
    __block SCRequest *req =
    [SCRequest performMethod:SCRequestMethodGET
                  onResource:[NSURL URLWithString:urlStr]
             usingParameters:nil
                 withAccount:nil
      sendingProgressHandler:nil
             responseHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                 [self removeRequest:req];
                 id result = nil;
                 if (!error) {
                     result = [UIImage imageWithData:data];
                 }
                 completion(result, error);
             }];
    [self addRequest:req];
    return req;
}

// Requests an image
// results: UIImage of image, or nil if error
- (AFHTTPRequestOperation *)requestImageAtURL:(NSString *)urlStr completion:(CSResponseHandler)completion {
    NSURLRequest *urlReq = [NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
    AFHTTPRequestOperation *req = [[[AFHTTPRequestOperation alloc] initWithRequest:urlReq] autorelease];
    [req setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id data) {
        [self removeRequest:req];
        id result = [UIImage imageWithData:data];
        completion(result, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self removeRequest:req];
        completion(nil, error);
    }];
    [self addRequest:req];
    [req start];
    return req;
}

- (AFHTTPRequestOperation *)requestNewsHeadline:(CSResponseHandler)completion {
    NSURLRequest *urlReq = [NSURLRequest requestWithURL:[NSURL URLWithString:kCSCustomHeadlineNewsURL]];
    AFHTTPRequestOperation *req = [[[AFHTTPRequestOperation alloc] initWithRequest:urlReq] autorelease];
    [req setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id data) {
        [self removeRequest:req];
        id results = nil;
        NSError *jsonError = nil;
        if (data) {
            id parsedData = [data objectFromJSONDataWithParseOptions:JKParseOptionStrict error:&jsonError];
            
            // Latest headline title
            results = [[[[[parsedData objectForKey:@"feed"] objectForKey:@"entry"] objectAtIndex:0] objectForKey:@"title"] objectForKey:@"$t"];
        }
        
        completion(results, jsonError);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self removeRequest:req];
        completion(nil, error);
    }];
    [self addRequest:req];
    [req start];
    return req;
}


#pragma mark - Request Handling
- (void)addRequest:(id)request {
    [mRequests addObject:request];
}

- (void)removeRequest:(id)request {
    [mRequests removeObject:request];
}

- (void)cancelRequests:(NSArray *)requestsToCancel {
    NSLog(@"cancelRequests = %@", requestsToCancel);
    for (id req in requestsToCancel) {
        [req cancel];
    }
    [mRequests removeObjectsInArray:requestsToCancel];
}

- (void)cancelAllRequests {
    NSLog(@"cancelAllRequests = %@", mRequests);
    for (id req in mRequests) {
        [req cancel];
    }
    [mRequests removeAllObjects];
}


#pragma mark - Private
- (id)init {
    if (self = [super init]) {
        [SCSoundCloud setClientID:SC_MY_CLIENT_ID
                           secret:SC_MY_CLIENT_SECRET
                      redirectURL:[NSURL URLWithString:SC_MY_REDIRECT_URL]];

        sDateFormatter = [[NSDateFormatter alloc] init];
        [sDateFormatter setDateFormat:@"yyyy/MM/dd HH:mm:ss ZZZZ"];
        
        mAllTrackLists = [[NSMutableArray alloc] initWithCapacity:kCSTrackList_Count];
        for (int i = 0; i < kCSTrackList_Count; i++) {
            [mAllTrackLists addObject:[[NSMutableArray alloc] initWithCapacity:TRACK_LIST_CAPACITY]];
        }
        
        mCommentsList = [[NSMutableArray alloc] initWithCapacity:20];
        mLikesList = [[NSMutableArray alloc] initWithCapacity:20];
        mMyAccount = [[NSMutableDictionary alloc] initWithCapacity:20];
        mShareConnections = [[NSMutableArray alloc] initWithCapacity:3];
        mActivityList = [[NSMutableArray alloc] initWithCapacity:20];
        mActivityTrackList = [[NSMutableDictionary alloc] initWithCapacity:20];
        mUserList = [[NSMutableDictionary alloc] initWithCapacity:20];
        mAppList = [[NSMutableDictionary alloc] initWithCapacity:5];
        mCursors = [[NSMutableDictionary alloc] initWithCapacity:5];
        mRequests = [[NSMutableArray alloc] initWithCapacity:5];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(soundCloudAccountDidChange:)
                                                     name:SCSoundCloudAccountDidChangeNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [mAllTrackLists release];
    [mCommentsList release];
    [mLikesList release];
    [mMyAccount release];
    [mActivityList release];
    [mActivityTrackList release];
    [mUserList release];
    [mAppList release];
    [mCursors release];
    [mRequests release];
    [mShareConnections release];
    
    [sDateFormatter release];
    
    [super dealloc];
}

- (void)soundCloudAccountDidChange:(NSNotification *)notification {
    // Remove user specific data
    [self clearAccountData];
    
    // Notify that user logged out
    if (![self isAccountReady]) {
         [[NSNotificationCenter defaultCenter] postNotificationName:kCSMyAccountDidChangeNotification object:self];
    }
}

+ (NSString *)getQueryValue:(NSString *)queryField fromURLString:(NSString *)urlStr {
    NSString *query = [[NSURL URLWithString:urlStr] query];
    for (NSString *comp in [query componentsSeparatedByString:@"&"]) {
        if ([comp hasPrefix:queryField]) {
            NSArray *pair = [comp componentsSeparatedByString:@"="];
            if ([[pair objectAtIndex:0] isEqualToString:queryField]) {
                return [pair objectAtIndex:1];
            }
        }
    }
    return nil;
}

@end
