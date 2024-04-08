//
//  LogManager.m
//  FlashThoughtPlatform
//
//  Created by tim on 2024/4/7.
//

#import "LogManager.h"

@interface LogManager ()

@property(strong) DDFileLogger *fileLogger;

@end

@implementation LogManager

+ (instancetype)sharedManager {
  static LogManager *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

+ (NSURL *)URLFromFileName:(NSString *)fileName {
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                       NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths objectAtIndex:0];
  NSString *filePath =
      [documentsDirectory stringByAppendingPathComponent:fileName];
  return [NSURL fileURLWithPath:filePath];
}

- (void)setupLogger {
  [DDLog addLogger:[DDOSLogger sharedInstance]];

  self.fileLogger = [[DDFileLogger alloc] init];
  self.fileLogger.rollingFrequency = 60 * 60 * 24;
  self.fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
  [DDLog addLogger:self.fileLogger];

  FLog(@"*** New Process ***, log_path:%@",
       self.fileLogger.currentLogFileInfo.filePath);
}

- (NSString *)getLogFilePath {
  return self.fileLogger.currentLogFileInfo.filePath;
}

@end
