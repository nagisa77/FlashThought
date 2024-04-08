//
//  LoginService.m
//  FlashThought
//
//  Created by tim on 2024/4/4.
//

#import "LoginService.h"
#import <Firebase/Firebase.h>
#import <FlashThoughtPlatform/LogManager.h>
#import <GoogleSignIn/GoogleSignIn.h>

@interface LoginService ()

@property(nonatomic, strong)
    NSMutableArray<id<LoginServiceDelegate>> *delegatesInternal;

@end

@implementation LoginService

+ (instancetype)sharedService {
  static LoginService *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

- (instancetype)init {
  if (self = [super init]) {
    _delegatesInternal = [NSMutableArray array];
  }
  return self;
}

- (void)initFIRConfig {
  [FIRApp configure];
}

- (void)gidSignInCompletionWithSignInResult:
            (GIDSignInResult *_Nullable)signInResult
                                      error:(NSError *_Nullable)error {
  if (error) {
    for (id<LoginServiceDelegate> delegate in self.delegates) {
      if ([delegate respondsToSelector:@selector(onSignOutSuccess)]) {
        [delegate onSignInFailed];
      }
    }
    FLog(@"Google登录失败: %@", error.localizedDescription);
    return;
  }
  [self firAuthWithGoogleUser:signInResult.user];
}

#if TARGET_OS_IPHONE
- (void)loginWithViewController:(UIViewController *)viewController {
  // Google Signin
  GIDConfiguration *configuration = [[GIDConfiguration alloc]
      initWithClientID:[FIRApp defaultApp].options.clientID];
  FLog(@"clientID: %@", [FIRApp defaultApp].options.clientID);
  [GIDSignIn.sharedInstance setConfiguration:configuration];
  [GIDSignIn.sharedInstance
      signInWithPresentingViewController:viewController
                              completion:^(
                                  GIDSignInResult *_Nullable signInResult,
                                  NSError *_Nullable error) {
                                [self
                                    gidSignInCompletionWithSignInResult:
                                        signInResult
                                                                  error:error];
                              }];
}
#elif TARGET_OS_OSX
- (void)loginWithWindow:(NSWindow *)window {
  GIDConfiguration *configuration = [[GIDConfiguration alloc]
      initWithClientID:[FIRApp defaultApp].options.clientID];
  FLog(@"clientID: %@", [FIRApp defaultApp].options.clientID);
  [GIDSignIn.sharedInstance setConfiguration:configuration];
  [GIDSignIn.sharedInstance
      signInWithPresentingWindow:window
                      completion:^(GIDSignInResult *_Nullable signInResult,
                                   NSError *_Nullable error) {
                        [self gidSignInCompletionWithSignInResult:signInResult
                                                            error:error];
                      }];
}
#endif

- (BOOL)isLoggedIn {
  return GIDSignIn.sharedInstance.currentUser != nil;
}

- (void)firAuthWithGoogleUser:(GIDGoogleUser *_Nullable)user {
  FIRAuthCredential *credential = [FIRGoogleAuthProvider
      credentialWithIDToken:user.idToken.tokenString
                accessToken:user.accessToken.tokenString];

  [[FIRAuth auth]
      signInWithCredential:credential
                completion:^(FIRAuthDataResult *_Nullable authResult,
                             NSError *_Nullable error) {
                  if (error) {
                    for (id<LoginServiceDelegate> delegate in self.delegates) {
                      if ([delegate
                              respondsToSelector:@selector(onSignInFailed)]) {
                        [delegate onSignInFailed];
                      }
                    }
                    return;
                  }
                  // 用户成功登录，继续应用流程
                  FLog(@"Google登录成功，用户UID"
                       @": %@",
                       authResult.user.uid);
                  for (id<LoginServiceDelegate> delegate in self.delegates) {
                    if ([delegate
                            respondsToSelector:@selector(onSignInSuccess)]) {
                      [delegate onSignInSuccess];
                    }
                  }
                }];
}

- (void)tryRelogin {
  GIDConfiguration *configuration = [[GIDConfiguration alloc]
      initWithClientID:[FIRApp defaultApp].options.clientID];
  [GIDSignIn.sharedInstance setConfiguration:configuration];

  [GIDSignIn.sharedInstance
      restorePreviousSignInWithCompletion:^(GIDGoogleUser *_Nullable user,
                                            NSError *_Nullable error) {
        if (error) {
          //          for (id<LoginServiceDelegate> delegate in self.delegates)
          //          {
          //            if ([delegate
          //            respondsToSelector:@selector(onSignOutSuccess)]) {
          //              [delegate onSignInFailed];
          //            }
          //          }
          FLog(@"relogin Google登录失败: %@", error.localizedDescription);
          return;
        }

        [self firAuthWithGoogleUser:user];
      }];
}

- (NSURL *)userAvatarURL {
  return
      [GIDSignIn.sharedInstance.currentUser.profile imageURLWithDimension:100];
}

- (NSString *)username {
  // Implement retrieval of username
  return GIDSignIn.sharedInstance.currentUser.profile.name;
}

- (void)logout {
  [GIDSignIn.sharedInstance signOut];
  [[FIRAuth auth] signOut:nil];

  // 如果需要，也可以断开连接，这将撤销token并清除应用的权限
  // [GIDSignIn.sharedInstance disconnectWithCallback:^(NSError * _Nullable
  // error) {
  //     if (error != nil) {
  //         // 处理可能发生的错误
  //         FLog(@"Error in disconnecting: %@", error.localizedDescription);
  //     } else {
  //         // 成功断开连接
  //         FLog(@"Successfully disconnected");
  //     }
  // }];

  // Implement logout functionality
  for (id<LoginServiceDelegate> delegate in self.delegates) {
    if ([delegate respondsToSelector:@selector(onSignOutSuccess)]) {
      [delegate onSignOutSuccess];
    }
  }
}

- (void)addDelegate:(id<LoginServiceDelegate>)delegate {
  if (![self.delegatesInternal containsObject:delegate]) {
    [self.delegatesInternal addObject:delegate];
  }
}

- (void)removeDelegate:(id<LoginServiceDelegate>)delegate {
  [self.delegatesInternal removeObject:delegate];
}

- (NSMutableArray<id<LoginServiceDelegate>> *)delegates {
  return [self.delegatesInternal copy];
}

@end
