//
//  ReminderManager.m
//  FlashThoughts
//
//  Created by tim on 2024/3/28.
//

#import "ReminderManager.h"
#import <Foundation/Foundation.h>
#import <FlashThoughtPlatform/LogManager.h>

@interface ReminderManager ()
@property(nonatomic, strong) EKEventStore *eventStore;
@end

@implementation ReminderManager

+ (instancetype)sharedManager {
  static ReminderManager *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
    sharedInstance.eventStore = [[EKEventStore alloc] init];
  });
  return sharedInstance;
}

- (void)addRemindersFromJsonString:(NSString *)jsonString
                       toListNamed:(NSString *)listName
                            withID:(NSUInteger)messageID {
  // 请求访问提醒事项
  [self.eventStore requestFullAccessToRemindersWithCompletion:^(
                       BOOL granted, NSError *_Nullable error) {
    if (!granted) {
      // 在主线程上回调，因为可能会更新UI
      dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate didFinishAddingRemindersWithSuccess:NO
                                                     error:error
                                                 messageID:messageID];
      });
      return;
    }

    // 解析JSON字符串
    NSDictionary *remindersDict = [NSJSONSerialization
        JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]
                   options:kNilOptions
                     error:&error];
    if (error) {
      // 在主线程上回调错误
      dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate didFinishAddingRemindersWithSuccess:NO
                                                     error:error
                                                 messageID:messageID];
      });
      return;
    }

    EKCalendar *reminderList = [self findOrCreateReminderListWithName:listName];
    if (!reminderList) {
      NSError *listError =
          [NSError errorWithDomain:@"com.yourdomain.appname"
                              code:500
                          userInfo:@{
                            NSLocalizedDescriptionKey :
                                @"Unable to find or create the reminder list."
                          }];
      dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate didFinishAddingRemindersWithSuccess:NO
                                                     error:listError
                                                 messageID:messageID];
      });
      return;
    }

    // 遍历字典，为每个项创建提醒
    __block BOOL isErrorOccurred = NO;
    [remindersDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj,
                                                       BOOL *stop) {
      EKReminder *reminder =
          [EKReminder reminderWithEventStore:self.eventStore];

      if (![obj isKindOfClass:[NSString class]] ||
          ![key isKindOfClass:[NSString class]]) {
        FLog(@"format error");
        isErrorOccurred = YES;
        *stop = YES;
        // 定义错误域和错误代码
        NSString *const CustomErrorDomain = @"com.tim.flashthought";
        NSInteger const CustomErrorCode = 1001;

        // 创建用户信息字典
        NSDictionary *userInfo = @{
          NSLocalizedDescriptionKey : NSLocalizedString(@"Error", nil),
          NSLocalizedFailureReasonErrorKey :
              NSLocalizedString(@"GPT Return format error", nil),
          NSLocalizedRecoverySuggestionErrorKey :
              NSLocalizedString(@"Please retry", nil)
        };

        NSError *error = [NSError errorWithDomain:CustomErrorDomain
                                             code:CustomErrorCode
                                         userInfo:userInfo];

        dispatch_async(dispatch_get_main_queue(), ^{
          [self.delegate didFinishAddingRemindersWithSuccess:NO
                                                       error:error
                                                   messageID:messageID];
        });
      }

      reminder.title = key;
      reminder.notes = obj;
      reminder.calendar = reminderList; // 指定列表

      NSError *addReminderError = nil;
      [self.eventStore saveReminder:reminder
                             commit:YES
                              error:&addReminderError];
      if (addReminderError) {
        isErrorOccurred = YES;
        *stop = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
          [self.delegate didFinishAddingRemindersWithSuccess:NO
                                                       error:addReminderError
                                                   messageID:messageID];
        });
      }
    }];

    if (!isErrorOccurred) {
      // 如果没有错误，发送成功回调
      dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate didFinishAddingRemindersWithSuccess:YES
                                                     error:nil
                                                 messageID:messageID];
      });
    }
  }];
}

// 获取或创建指定名称的提醒事项列表
- (EKCalendar *)findOrCreateReminderListWithName:(NSString *)listName {
  // 查找现有的提醒事项列表
  NSArray<EKCalendar *> *calendars =
      [self.eventStore calendarsForEntityType:EKEntityTypeReminder];
  for (EKCalendar *calendar in calendars) {
    if ([calendar.title isEqualToString:listName]) {
      return calendar;
    }
  }

  // 创建新的提醒事项列表
  EKCalendar *newCalendar =
      [EKCalendar calendarForEntityType:EKEntityTypeReminder
                             eventStore:self.eventStore];
  newCalendar.title = listName;
  newCalendar.source = self.eventStore.defaultCalendarForNewReminders.source;

  NSError *error = nil;
  [self.eventStore saveCalendar:newCalendar commit:YES error:&error];
  if (error) {
    FLog(@"Error creating calendar: %@", error.localizedDescription);
    return nil;
  }

  return newCalendar;
}

@end
