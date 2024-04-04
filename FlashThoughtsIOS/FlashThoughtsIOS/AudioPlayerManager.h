//
//  AudioPlayerManager.h
//  FlashThoughts
//
//  Created by tim on 2024/4/2.
//

#ifndef AudioPlayerManager_h
#define AudioPlayerManager_h

#import <Foundation/Foundation.h>

@protocol AudioPlayerManagerDelegate <NSObject>
- (void)audioPlayerShouldPause;
- (void)audioPlayerShouldStop;
@end

@interface AudioPlayerManager : NSObject

+ (instancetype)sharedManager;
- (void)subscribe:(id<AudioPlayerManagerDelegate>)player;
- (void)unsubscribe:(id<AudioPlayerManagerDelegate>)player;
- (void)stopAllPlayers;
- (void)pauseAllPlayers;

@end

#endif /* AudioPlayerManager_h */
