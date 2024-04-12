//
//  FlashThoughtManager.h
//  FlashThoughts
//
//  Created by tim on 2024/3/27.
//

#ifndef FlashThoughtManager_h
#define FlashThoughtManager_h

#import <FlashThoughtPlatform/GPTVisitor.h>
#import <FlashThoughtPlatform/LoginService.h>
#import <FlashThoughtPlatform/ReminderManager.h>
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
    : NSObject <GPTVisitorDelegate, ReminderManagerDelegate,
                LoginServiceDelegate>

@property(nonatomic, strong)
    NSMutableArray<id<FlashThoughtManagerDelegate>> *delegates;

@property(nonatomic, assign) BOOL isHandlingAllThoughts;

+ (instancetype)sharedManager;

- (void)loadStoredThoughts;
- (NSArray<FlashThought *> *)allThoughts;
- (void)addThought:(FlashThought *)thought;
- (void)addThought:(FlashThought *)thought reload:(BOOL)reload;
- (NSInteger)removeThought:(FlashThought *)thought;
- (void)updateThought:(FlashThought *)thought withContent:(NSString *)content;
- (BOOL)sendAllThoughtsToAI;
- (void)cancelSendAllThoughtsToAI;

- (void)addDelegate:(id<FlashThoughtManagerDelegate>)delegate;
- (void)removeDelegate:(id<FlashThoughtManagerDelegate>)delegate;

@end

#endif /* FlashThoughtManager_h */
