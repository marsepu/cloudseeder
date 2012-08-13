//
//  CSCloudSeederConfig.h
//  CloudSeeder
//
//  Created by David Shu on 4/24/12.
//  Copyright (c) 2012 Retronyms. All rights reserved.
//

// These are details found at http://soundcloud.com/you/apps/<YOUR_APP_NAME>/edit
// Make sure they are defined as NSStrings!
#define SC_MY_CLIENT_ID                 (@"some long string of random characters and numbers")
#define SC_MY_CLIENT_SECRET             (@"another long string of random characters and numbers")
#define SC_MY_REDIRECT_URL              (@"some url")

// These are details you find using SoundCloud API's /resolve. Find out how to do that here:
// http://developers.soundcloud.com/docs/api/reference#resolve
// Make sure they are defined as integers!
#define SC_MY_APP_ID                    (12345)     // Resolve your app URL to get this number
#define SC_MY_FEATURED_USER_ID          (123456)    // Resolve your user URL to get this number
#define SC_MY_GROUP_ID                  (12345)     // Resolve your group URL to get this number

// CloudSeeder Cross Promo
// YES to cross promote your app with other CloudSeeder apps, otherwise NO
#define CS_USE_CLOUDSEEDER_SELECT       (YES)

// CloudSeeder's news section will go to this address
#define kCSCustomNewsURL                (@"http://www.retronyms.com/tabletop/news")
// Takes the latest item of your Blogger blog feed and displays it in the Headline feed
#define kCSCustomHeadlineNewsURL        (@"http://blog.retronyms.com/feeds/posts/default/-/Tabletop?alt=json")
// Your app name
#define kCSCustomAppStringValue         (@"MyAwesomeApp")
// Your app icon
#define kCSCustomJoinIcon               (@"icon.png")
// What you refer to your sounds as. Ex: "songs", "tracks", "beats"
#define kCSCustomTrackStringValue       (@"song")
#define kCSCustomTrackPluralStringValue (@"songs")
// String processing for showing text on buttons and other controls
#define CSCustomControlCase(str)        ([(str) uppercaseString])

// Use the dark theme by commenting out the #define below
// Use the light theme by uncommenting the #define below
//#define CLOUDSEEDER_LIGHT_THEME 

// Unused right now
#define kCSCustomPrimaryColor           [UIColor redColor]
#define kCSCustomSecondaryColor         [UIColor greenColor]