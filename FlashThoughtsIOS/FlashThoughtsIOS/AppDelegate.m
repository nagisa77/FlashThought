//
//  AppDelegate.m
//  FlashThoughts
//
//  Created by tim on 2024/3/26.
//

#import "AppDelegate.h"
#import <FlashThoughtPlatform/LogManager.h>
#import <FlashThoughtPlatform/LoginService.h>
@import Firebase;

@interface AppDelegate ()

@property (assign) UIBackgroundTaskIdentifier backgroundTaskIdentifier;

@end

@implementation AppDelegate

- (void)allThoughtsDidHandle {
  FLog(@"all tasks handled");
  BOOL isInBackground = [UIApplication sharedApplication].applicationState == UIApplicationStateBackground;
  if (isInBackground) {
    [self endBackgroundUpdateTask];
  }
}

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [[LogManager sharedManager] setupLogger];
  [[LoginService sharedService] initFIRConfig];
  [[LoginService sharedService] tryRelogin];
  [[FlashThoughtManager sharedManager] addDelegate:self];
  
  [[NSNotificationCenter defaultCenter]
      addObserver:self
         selector:@selector(appDidEnterBackground:)
             name:UIApplicationDidEnterBackgroundNotification
           object:nil];
  
  return YES;
}

- (void)endBackgroundUpdateTask {
  FLog(@"endBackgroundUpdateTask");
    [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
    self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
}

- (void)beginBackgroundUpdateTask {
  FLog(@"beginBackgroundUpdateTask");
    self.backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        // 当额外获得的时间即将耗尽时，这个block会被调用
        // 在这里结束任务，清理环境
        [self endBackgroundUpdateTask];
    }];
}

- (void)appDidEnterBackground:(NSNotification *)notification {
  if ([[FlashThoughtManager sharedManager] isHandlingAllThoughts]) {
    FLog(@"Is still handling tasks...");
    [self beginBackgroundUpdateTask];
  }
}

#pragma mark - UISceneSession lifecycle

- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:
        (UISceneSession *)connectingSceneSession
                                   options:(UISceneConnectionOptions *)options {
  // Called when a new scene session is being created.
  // Use this method to select a configuration to create the new scene with.
  return
      [[UISceneConfiguration alloc] initWithName:@"Default Configuration"
                                     sessionRole:connectingSceneSession.role];
}

- (void)application:(UIApplication *)application
    didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
  // Called when the user discards a scene session.
  // If any sessions were discarded while the application was not running, this
  // will be called shortly after application:didFinishLaunchingWithOptions. Use
  // this method to release any resources that were specific to the discarded
  // scenes, as they will not return.
}

@end
