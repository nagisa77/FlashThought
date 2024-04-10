//
//  DatabaseManager.h
//  FlashThought
//
//  Created by tim on 2024/4/4.
//

#ifndef DatabaseManager_h
#define DatabaseManager_h

#import <Foundation/Foundation.h>

#define APP_GROUP_NAME @"group.tim.flashThoughts"

@interface DatabaseManager : NSObject

+ (instancetype)sharedManager; // todo: (reconstruct)
- (void)observeUserBase64DataWithCompletion:(void (^)(NSData *data))completion;
- (void)observeUserAPIKeyCompletion:(void (^)(NSString *apikey))completion;
- (void)observeUserHostWithCompletion:(void (^)(NSString *host))completion;
- (void)loadAllDataWithCompletion:(void (^)(NSData *data))completion;
- (void)loadAPIKeyWithCompletion:(void (^)(NSString *apiKey))completion;
- (void)loadHostWithCompletion:(void (^)(NSString *host))completion;
- (void)saveData:(NSData *)data;
- (void)saveAPIKey:(NSString *)apiKey;
- (void)saveHost:(NSString *)host; 

@end

#endif /* DatabaseManager_h */
