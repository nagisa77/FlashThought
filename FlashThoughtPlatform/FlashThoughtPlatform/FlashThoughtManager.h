//
//  FlashThoughtManager.h
//  FlashThoughts
//
//  Created by tim on 2024/3/27.
//

#ifndef FlashThoughtManager_h
#define FlashThoughtManager_h

#import <FlashThoughtPlatform/GPTVisitor.h>
#import <FlashThoughtPlatform/ReminderManager.h>
#import <FlashThoughtPlatform/LoginService.h>
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, FlashThoughtType) {
  FlashThoughtTypeTextFlashThought,
  FlashThoughtTypeAudioFlashThought,
  FlashThoughtTypeAudioToTextFlashThought,
};

@interface FlashThought : NSObject <NSSecureCoding>

@property(nonatomic, assign) FlashThoughtType type;
@property(nonatomic, strong) NSDate *date;
@property(nonatomic, strong) NSString *content;
@property(nonatomic, strong) NSString *audioFileName;

- (instancetype)initWithType:(FlashThoughtType)type date:(NSDate *)date;

@end

@protocol FlashThoughtManagerDelegate <NSObject>

- (void)thoughtManagerDidAddThought:(FlashThought *)thought;
- (void)thoughtManagerDidRemoveThought:(FlashThought *)thought;
- (void)thoughtManagerDidUpdateThought:(FlashThought *)thought;
- (void)thoughtsDidSentToAI:(NSArray<FlashThought *> *)thoughts;
- (void)thoughtsDidSaveToReminders:(NSArray<FlashThought *> *)thoughts;
- (void)allThoughtsDidHandle;
- (void)shouldReloadData;
- (void)shouldStopHandlingThoughtsByError:(NSError *)error;

@end

@interface FlashThoughtManager
    : NSObject <GPTVisitorDelegate, ReminderManagerDelegate, LoginServiceDelegate>

@property(nonatomic, weak) id<FlashThoughtManagerDelegate> delegate;

@property(nonatomic, assign) BOOL isHandlingAllThoughts;

+ (NSURL *)audioRecordingURLFromFileName:(NSString *)fileName;
+ (instancetype)sharedManager;

- (void)loadStoredThoughts;
- (NSArray<FlashThought *> *)allThoughts;
- (void)addThought:(FlashThought *)thought;
- (NSInteger)removeThought:(FlashThought *)thought;
- (void)updateThought:(FlashThought *)thought withContent:(NSString *)content;
- (BOOL)sendAllThoughtsToAI;
- (void)cancelSendAllThoughtsToAI;

@end

#endif /* FlashThoughtManager_h */
