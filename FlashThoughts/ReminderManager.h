//
//  ReminderManager.h
//  FlashThoughts
//
//  Created by tim on 2024/3/28.
//

#ifndef ReminderManager_h
#define ReminderManager_h

#import <EventKit/EventKit.h>
#import <Foundation/Foundation.h>

@protocol ReminderManagerDelegate <NSObject>
- (void)didFinishAddingRemindersWithSuccess:(BOOL)success
                                      error:(NSError *)error
                                  messageID:(NSUInteger)messageID;
@end

@interface ReminderManager : NSObject

@property(nonatomic, weak) id<ReminderManagerDelegate> delegate;

+ (instancetype)sharedManager;
- (void)addRemindersFromJsonString:(NSString *)jsonString
                       toListNamed:(NSString *)listName
                            withID:(NSUInteger)messageID;

@end

#endif /* ReminderManager_h */
