//
//  FlashThoughtManager.h
//  FlashThoughts
//
//  Created by tim on 2024/3/27.
//

#ifndef FlashThoughtManager_h
#define FlashThoughtManager_h

#import <Foundation/Foundation.h>
#import "GPTVisitor.h"

@interface FlashThought : NSObject <NSSecureCoding>

@property(nonatomic, strong) NSDate *date;
@property(nonatomic, strong) NSString *content;

@end

@protocol FlashThoughtManagerDelegate <NSObject>

- (void)thoughtManagerDidAddThought:(FlashThought *)thought;
- (void)thoughtManagerDidRemoveThought:(FlashThought *)thought;
- (void)thoughtManagerDidUpdateThought:(FlashThought *)thought;

- (void)thoughtDidSentToAI:(FlashThought *)thought;
- (void)thoughtsDidResponseByAI:(NSString *)aiJsonResponse;

@end

@interface FlashThoughtManager : NSObject<GPTVisitorDelegate>

@property(nonatomic, weak) id<FlashThoughtManagerDelegate> delegate;

+ (instancetype)sharedManager;

- (void)loadStoredThoughts;
- (NSArray<FlashThought *> *)allThoughts;
- (void)addThought:(FlashThought *)thought;
- (void)removeThought:(FlashThought *)thought;
- (void)updateThought:(FlashThought *)thought withContent:(NSString *)content;
- (void)sendAllThoughtsToAI;

@end

#endif /* FlashThoughtManager_h */
