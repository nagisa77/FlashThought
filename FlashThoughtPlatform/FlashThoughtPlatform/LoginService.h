//
//  LoginService.h
//  FlashThought
//
//  Created by tim on 2024/4/4.
//

#ifndef LoginService_h
#define LoginService_h

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#elif TARGET_OS_OSX
#import <AppKit/AppKit.h>
#endif

@protocol LoginServiceDelegate <NSObject>

- (void)onSignInSuccess;
- (void)onSignInFailed;
- (void)onSignOutSuccess;

@end

@interface LoginService : NSObject

@property(nonatomic, strong, readonly)
    NSMutableArray<id<LoginServiceDelegate>> *delegates;

+ (instancetype)sharedService;
- (void)initFIRConfig;
#if TARGET_OS_IPHONE
- (void)loginWithViewController:(UIViewController *)viewController;
#elif TARGET_OS_OSX
- (void)loginWithWindow:(NSWindow *)window;
#endif
- (BOOL)isLoggedIn;
- (void)tryRelogin;
- (NSURL *)userAvatarURL;
- (NSString *)username;
- (void)logout;

- (void)addDelegate:(id<LoginServiceDelegate>)delegate;
- (void)removeDelegate:(id<LoginServiceDelegate>)delegate;

@end

#endif /* LoginService_h */
