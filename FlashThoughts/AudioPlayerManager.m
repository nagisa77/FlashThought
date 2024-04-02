//
//  AudioPlayerManager.m
//  FlashThoughts
//
//  Created by tim on 2024/4/2.
//

#import "AudioPlayerManager.h"
#import <Foundation/Foundation.h>

@interface AudioPlayerManager ()

@property(strong, nonatomic)
    NSMutableArray<id<AudioPlayerManagerDelegate>> *subscribers;

@end

@implementation AudioPlayerManager

+ (instancetype)sharedManager {
  static AudioPlayerManager *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

- (instancetype)init {
  if (self = [super init]) {
    _subscribers = [NSMutableArray array];
  }
  return self;
}

- (void)subscribe:(id<AudioPlayerManagerDelegate>)player {
  if (![self.subscribers containsObject:player]) {
    [self.subscribers addObject:player];
  }
}

- (void)unsubscribe:(id<AudioPlayerManagerDelegate>)player {
  [self.subscribers removeObject:player];
}

- (void)stopAllPlayers {
  for (id<AudioPlayerManagerDelegate> player in self.subscribers) {
    [player audioPlayerShouldStop];
  }
}

- (void)pauseAllPlayers {
  for (id<AudioPlayerManagerDelegate> player in self.subscribers) {
    [player audioPlayerShouldPause];
  }
}

@end
