//
//  CSCloudSeeder.h
//  CloudSeeder
//
//  Created by David Shu on 3/23/12.
//  Copyright (c) 2012 Retronyms. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSBundle.h"

typedef void(^CSResponseHandler)(id obj, NSError *error);

#define SOUNDCLOUD_BASE_URL             (@"https://api.soundcloud.com")
#define SOUNDCLOUD_ME_URL               ([NSString stringWithFormat:@"%@/me.json", SOUNDCLOUD_BASE_URL])
#define SOUNDCLOUD_ME_EMAIL_URL         ([NSString stringWithFormat:@"%@/me/email.json", SOUNDCLOUD_BASE_URL])
#define SOUNDCLOUD_ME_CONNECTIONS_URL   ([NSString stringWithFormat:@"%@/me/connections.json", SOUNDCLOUD_BASE_URL])
#define SOUNDCLOUD_ME_ACTIVITIES_URL    ([NSString stringWithFormat:@"%@/me/activities/all/own.json", SOUNDCLOUD_BASE_URL])
#define SOUNDCLOUD_FEATURED_URL         ([NSString stringWithFormat:@"%@/users/%d/favorites.json", SOUNDCLOUD_BASE_URL, kMyFeaturedUserId])
#define SOUNDCLOUD_APP_TRACKS_URL       ([NSString stringWithFormat:@"%@/apps/%d/tracks.json", SOUNDCLOUD_BASE_URL, SC_MY_APP_ID])
#define SOUNDCLOUD_RESOLVE_URL          ([NSString stringWithFormat:@"%@/resolve.json", SOUNDCLOUD_BASE_URL])
#define SOUNDCLOUD_FOLLOWING_URL        ([NSString stringWithFormat:@"%@/me/activities/tracks/affiliated.json", SOUNDCLOUD_BASE_URL])
#define CLOUDSEEDER_SELECT_URL          (@"http://cloudseeder.retronyms.com/csselect.py?app_id=%d")

typedef enum {
    kCSTrackList_Featured = 0,
    kCSTrackList_Popular,
    kCSTrackList_Latest,
    kCSTrackList_MyUploads,
    kCSTrackList_Following,
    kCSTrackList_Count      // Must be last!
} CSTrackListType;

typedef enum {
    kCSError_NoNetwork = 5000,
    kCSError_CantStreamTrack = 5001,
} CSErrorType;

typedef enum {
    kCSShare_Facebook = 0,
    kCSShare_Twitter,
    kCSShare_Tumblr,
    kCSShare_Count          // Must be last!
} CSShareType;

typedef enum {
    kCSImageURLType_t500x500,     // 500 x 500
    kCSImageURLType_crop,         // 400 x 400
    kCSImageURLType_t300x300,     // 300 x 300
    kCSImageURLType_large,        // 100 x 100 (default)
    
    kCSImageURLType_t67x67,       // 67 x 67 (only on artworks)
    kCSImageURLType_badge,        // 47 x 47
    kCSImageURLType_small,        // 32 x 32
    kCSImageURLType_tiny,         // 20 x 20 (on artworks), 18 x 18 (on avatars)

    kCSImageURLType_mini,         // 16 x 16
    kCSImageURLType_original,     // originally uploaded image
} CSImageURLType;

#define kCSItemsPerRequest (10)
extern NSString * const kCSMyAccountDidChangeNotification;
extern NSString * const kCSMyAccountActivityNotification;
extern const BOOL kIsUsingCloudSeederSelect;
extern const NSUInteger kMyGroupId;


@class CSUser;
@class SCRequest;
@class AFHTTPRequestOperation;
@interface CSCloudSeeder : NSObject {
    // Featured, popular, latest, etc. track lists here
    NSMutableArray *mAllTrackLists;
    
    // Data for a specific track
    NSMutableArray *mCommentsList;
    NSMutableArray *mLikesList;
    
    // Account related data
    NSMutableDictionary *mMyAccount;
    NSMutableArray *mShareConnections;
    NSMutableDictionary *mCursors;
    
    // Activities
    NSMutableArray *mActivityList;
    NSMutableDictionary *mActivityTrackList;
    
    // Users cache (images, names)
    NSMutableDictionary *mUserList;
    
    // Apps
    NSMutableDictionary *mAppList;
    
    // Current requests
    NSMutableArray *mRequests;
}
@property (nonatomic, readonly) NSMutableArray *allTrackLists;
@property (nonatomic, readonly) NSMutableArray *commentsList;
@property (nonatomic, readonly) NSMutableArray *likesList;
@property (nonatomic, readonly) NSMutableDictionary *myAccount;
@property (nonatomic, readonly) NSMutableArray *activityList;
@property (nonatomic, readonly) NSMutableDictionary *activityTrackList;
@property (nonatomic, readonly) NSMutableDictionary *userList;
@property (nonatomic, readonly) NSMutableDictionary *appList;

+ (CSCloudSeeder *)sharedCSCloudSeeder;

// CloudSeeder Data
- (void)clearAllData;

// SoundCloud API Helpers
- (NSString *)URLString:(NSString *)url;
+ (NSDate *)dateFromString:(NSString *)dateStr;
+ (NSString *)dateAgoString:(NSDate *)date;
+ (BOOL)isTrackCreatedWithApp:(NSDictionary *)trackDict;
// Cursor
- (NSString *)cursorForURL:(NSString *)urlStr;
- (void)removeCursorForURL:(NSString *)urlStr;

// My Account
- (BOOL)isAccountReady;
- (void)logoutAccount;
- (NSArray *)idsForShareConnection:(CSShareType)shareType;

// User
- (NSString *)userIdKey:(NSUInteger)userId;
- (CSUser *)userForId:(NSUInteger)userId;

// Requests:
// Manage requests
- (void)cancelAllRequests;
- (void)cancelRequests:(NSArray *)requestsToCancel;
// My account
- (SCRequest *)requestMe:(CSResponseHandler)completion;
- (SCRequest *)requestMeUpdate:(CSResponseHandler)completion;
- (SCRequest *)requestMeConnections:(CSResponseHandler)completion;
- (SCRequest *)requestIsFollowingUser:(NSUInteger)otherUserId completion:(CSResponseHandler)completion;
// Activities
- (SCRequest *)requestMeActivities:(NSString *)cursor limit:(NSUInteger)limit completion:(CSResponseHandler)completion;
- (SCRequest *)requestTracksForMeActivites:(CSResponseHandler)completion;
// Track
- (SCRequest *)requestAddTrack:(NSInteger)trackId toGroup:(NSInteger)groupId completion:(CSResponseHandler)completion;
- (SCRequest *)requestUpdateTrack:(NSInteger)trackId metadata:(NSDictionary *)metadata completion:(CSResponseHandler)completion;
- (SCRequest *)requestFollow:(BOOL)doFollow user:(NSUInteger)userId completion:(CSResponseHandler)completion;
- (SCRequest *)requestFavorite:(BOOL)isFavorite track:(NSUInteger)trackId completion:(CSResponseHandler)completion;
- (SCRequest *)requestComment:(NSString *)comment track:(NSUInteger)trackId completion:(CSResponseHandler)completion;
- (SCRequest *)requestShareTrack:(NSUInteger)trackId withNote:(NSString *)note onConnections:(NSArray *)connections completion:(CSResponseHandler)completion;
- (SCRequest *)requestTrackComments:(NSUInteger)trackId completion:(CSResponseHandler)completion;
- (SCRequest *)requestTrackFavoriters:(NSUInteger)trackId completion:(CSResponseHandler)completion;
// Track lists
- (AFHTTPRequestOperation *)requestCloudSeederSelectTrackForList:(NSMutableArray *)list completion:(CSResponseHandler)completion;
//- (SCRequest *)requestApp:(NSUInteger)appId completion:(CSResponseHandler)completion;
- (SCRequest *)requestTracksWithIds:(NSArray *)trackIds completion:(CSResponseHandler)completion;
- (SCRequest *)requestTrackList:(CSTrackListType)listType limit:(NSUInteger)limit offset:(NSUInteger)offset completion:(CSResponseHandler)completion;
- (SCRequest *)requestTrackList:(CSTrackListType)listType limit:(NSUInteger)limit cursor:(NSString *)cursor completion:(CSResponseHandler)completion;
// Images
- (SCRequest *)requestUserImage:(NSString *)urlStr userId:(NSUInteger)userId imageType:(CSImageURLType)imageType completion:(CSResponseHandler)completion;
- (SCRequest *)requestTrackImage:(NSString *)urlStr trackId:(NSUInteger)trackId imageType:(CSImageURLType)imageType completion:(CSResponseHandler)completion;
- (AFHTTPRequestOperation *)requestImageAtURL:(NSString *)urlStr completion:(CSResponseHandler)completion;
// Headline
- (AFHTTPRequestOperation *)requestNewsHeadline:(CSResponseHandler)completion;
@end
