//
//  LogManager.h
//  FlashThoughtPlatform
//
//  Created by tim on 2024/4/7.
//

#ifndef LogManager_h
#define LogManager_h

#import <CocoaLumberjack/CocoaLumberjack.h>

#include <pthread.h>

static const DDLogLevel ddLogLevel = DDLogLevelVerbose;

#define FLog(message, ...) DDLogVerbose(@"%s\t|%s\t|line:%d\t|t:%lu\t|%@", \
    [[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], \
    __PRETTY_FUNCTION__, \
    __LINE__, \
    (unsigned long)pthread_self(), \
    [NSString stringWithFormat:(message), ##__VA_ARGS__])


@interface LogManager : NSObject

+ (instancetype)sharedManager;
+ (NSURL *)URLFromFileName:(NSString *)fileName;
- (void)setupLogger;
- (NSString *)getLogFilePath; 

@end

#endif /* LogManager_h */
