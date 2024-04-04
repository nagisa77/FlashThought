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

+ (instancetype)sharedManager;
- (void)observeUserDataWithCompletion:(void (^)(NSData *data))completion;
- (void)loadAllDataWithCompletion:(void (^)(NSData *data))completion;
- (void)saveData:(NSData *)data;

@end

#endif /* DatabaseManager_h */
