//
//  LoginService.h
//  FlashThought
//
//  Created by tim on 2024/4/4.
//

#ifndef LoginService_h
#define LoginService_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

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
- (void)loginWithViewController:(UIViewController *)viewController;
- (BOOL)isLoggedIn;
- (void)tryRelogin;
- (NSURL *)userAvatarURL;
- (NSString *)username;
- (void)logout;

- (void)addDelegate:(id<LoginServiceDelegate>)delegate;
- (void)removeDelegate:(id<LoginServiceDelegate>)delegate;

@end

#endif /* LoginService_h */
