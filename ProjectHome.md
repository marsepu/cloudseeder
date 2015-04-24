# Overview #

The CloudSeeder devkit allows you to easily add a SoundCloud-powered community to your iPad app.  Users will be able to upload tracks, glance at the latest headlines, browse, stream and interact with tracks--all from within your app.


---

# Setup #

## SoundCloud ##

First we're going to make sure have all your SoundCloud resources ready.  This means having an app in the App Gallery, a user to pick featured tracks, and a group for tracks to be added to.

1. Make sure you have an app in SoundCloud's [App Gallery](http://soundcloud.com/you/apps) and have your client id handy.

2. Resolve your app's id. With your client id and app name (Ex: "MyAwesomeApp"), type this into Terminal:

```
curl -v 'http://api.soundcloud.com/resolve.json?url=http://soundcloud.com/apps/MyAwesomeApp&client_id=YOUR_CLIENT_ID'
...
< HTTP/1.1 302 Moved Temporarily
< Location: http://api.soundcloud.com/apps/12345.json <-- Remember this number!
```

3. Tracks show up in the "Featured" tab by having a single designated user favorite a track. Resolve your user's id:

```
curl -v 'http://api.soundcloud.com/resolve.json?url=http://soundcloud.com/jwagener&client_id=YOUR_CLIENT_ID'
```

4. Tracks uploaded using CloudSeeder also get automatically added to a group of your choice. Resolve your group's id:

```
curl -v 'http://api.soundcloud.com/resolve.json?url=http://soundcloud.com/groups/MyAwesomeGroup&client_id=YOUR_CLIENT_ID'
```

5. Remember these id's. You'll use them in the Xcode section below!

## In Xcode ##
1. Get SoundCloud's [CocoaSoundCloudAPI](https://github.com/soundcloud/CocoaSoundCloudAPI) and follow the setup instructions there to add it to your project.

2. Get CloudSeeder

```
svn checkout http://cloudseeder.googlecode.com/svn/trunk/ cloudseeder-read-only
```

3. Add all the source and image files from CloudSeeder to your project.

4. Go to your _Project_, select the _Target_, select the _Build Phases_ tab, then go to the _Link Binary With Libraries_ section and add:

```
AudioToolbox.framework 	// for audio streaming.
```

5. Go to `CSCloudSeederConfig.h` and fill in the details you got in the SoundCloud setup section.

```
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
```



---

# Usage #

`#import "CloudSeederAPI.h"` to use any CloudSeeder module.

## Adding the Headline to your code ##
CloudSeeder begins with the Headline view.  Users can check out the latest news for your app, the latest track uploaded, and activity on their tracks.  When they tap on the headline, the Main view slides up and the user can then participate in your CloudSeeder community.

In your view controller's header file:

```
#import "CloudSeederAPI.h"
...
CSHeadlineViewController *mHeadline;
```

In your view controller's `viewDidLoad`:

```
mHeadline = [[CSHeadlineViewController alloc] initWithNibName:@"CSHeadlineViewController" bundle:nil];
mHeadline.delegate = self;
mHeadline.presenterViewController = self;
[self.view addSubview:mHeadline.view];
```

## Uploading a track ##

CloudSeeder's uploading view controller is called `CSRecordingSaveViewController`, which is a subclass of CocoaSoundCloudAPI's SCRecordingSaveViewController.  There's some extra functionality here to automatically add the track to the appropriate SoundCloud groups, but you interface with it in the exact same way:

```
CSShareViewController *share = [CSShareViewController shareViewControllerWithFileURL:[NSURL fileURLWithPath:savedFilepath]
                                                                     completionHandler:^(NSDictionary *trackInfo, NSError *error) {}];
[self presentModalViewController:share animated:YES];
```


---

# More Customization #
There's more customization features in `CSCloudSeederConfig.h` to suit CloudSeeder to your app's needs.

```
// CloudSeeder's news section will go to this address
#define kCSCustomNewsURL                (@"http://www.retronyms.com/tabletop/news")
// Takes the latest item of your Blogger blog feed and displays it in the Headline feed
#define kCSCustomHeadlineNewsURL        (@"http://blog.retronyms.com/feeds/posts/default/-/Tabletop?alt=json")
// Your app name
#define kCSCustomAppStringValue         (@"MyAwesomeApp")
// Your app icon
#define kCSCustomJoinIcon               (@"icon.png")
// What you refer to your sounds as. Ex: "songs", "tracks", "beats"
#define kCSCustomTrackStringValue       (@"track")
#define kCSCustomTrackPluralStringValue (@"tracks")
// String processing for showing text on buttons and other controls
#define CSCustomControlCase(str)        ([(str) uppercaseString])
```

CloudSeeder also comes with two built-in themes, "light" and "dark".

```
// Use the dark theme by commenting out the #define below
// Use the light theme by uncommenting the #define below
//#define CLOUDSEEDER_LIGHT_THEME
```


---

# Cross Promote your app with CloudSeeder Select #
CloudSeeder Select is a feature that allows you to promote your app across other CloudSeeder apps. Apps that are a part of CloudSeeder Select get featured across all other CloudSeeder Select apps.  When users check out their Featured Tracks list, one track out of that list will be a featured track from another fellow CloudSeeder app.  Tapping on that track will show the usual track view, along with a section at the top with a small promo.

Here's what to do to be a part of CloudSeeder Select:

  1. Make sure CS\_CLOUDSEEDER\_SELECT is defined as YES in `CSCloudSeederConfig.h`

```
// CloudSeeder Cross Promo
// YES to cross promote your app with other CloudSeeder apps, otherwise NO
#define CS_USE_CLOUDSEEDER_SELECT       (YES)
```

2. Send an email to <the name of this project>@retronyms.com with the following information:

  * Name of your app
  * Your SoundCloud App Gallery app id (defined as `SC_MY_APP_ID` in `CSCloudSeederConfig.h`)
  * Username and id of the user you use to feature tracks (defined as `SC_MY_FEATURED_USER_ID` in `CSCloudSeederConfig.h`) -- this is used to serve tracks to other apps
  * A 72x72 px icon image for your app

3. Make sure your SoundCloud App Gallery "App URL" field is your Apple App Store URL. Users will be taken to the App Store when they tap on the "Get this app" button.


---

# See you on CloudSeeder! #