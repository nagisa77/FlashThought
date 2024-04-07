//
//  AppDelegate.m
//  FlashThoughts
//
//  Created by tim on 2024/3/26.
//

#import "AppDelegate.h"
#import <FlashThoughtPlatform/FlashThoughtManager.h>
#import <FlashThoughtPlatform/LoginService.h>
#import <FlashThoughtPlatform/LogManager.h>
@import Firebase;

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [[LogManager sharedManager] setupLogger]; 
  [[LoginService sharedService] initFIRConfig];
  [[LoginService sharedService] tryRelogin];
  return YES;
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
