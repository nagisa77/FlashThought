//
//  FlashThoughtManager.h
//  FlashThoughts
//
//  Created by tim on 2024/3/27.
//

#ifndef FlashThoughtManager_h
#define FlashThoughtManager_h

#import "GPTVisitor.h"
#import "ReminderManager.h"
#import <Foundation/Foundation.h>

@interface FlashThought : NSObject <NSSecureCoding>

@property(nonatomic, strong) NSDate *date;
@property(nonatomic, strong) NSString *content;

@end

@protocol FlashThoughtManagerDelegate <NSObject>

- (void)thoughtManagerDidAddThought:(FlashThought *)thought;
- (void)thoughtManagerDidRemoveThought:(FlashThought *)thought;
- (void)thoughtManagerDidUpdateThought:(FlashThought *)thought;
- (void)thoughtsDidSentToAI:(NSArray<FlashThought *> *)thoughts;
- (void)thoughtsDidSaveToReminders:(NSArray<FlashThought *> *)thoughts;
- (void)allThoughtsDidHandle;

@end

@interface FlashThoughtManager
    : NSObject <GPTVisitorDelegate, ReminderManagerDelegate>

@property(nonatomic, weak) id<FlashThoughtManagerDelegate> delegate;

+ (instancetype)sharedManager;

- (void)loadStoredThoughts;
- (NSArray<FlashThought *> *)allThoughts;
- (void)addThought:(FlashThought *)thought;
- (NSInteger)removeThought:(FlashThought *)thought;
- (void)updateThought:(FlashThought *)thought withContent:(NSString *)content;
- (BOOL)sendAllThoughtsToAI;

@end

#endif /* FlashThoughtManager_h */
