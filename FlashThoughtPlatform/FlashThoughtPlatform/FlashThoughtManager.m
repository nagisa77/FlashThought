//
//  FlashThoughtManager.m
//  FlashThoughts
//
//  Created by tim on 2024/3/27.
//

#import "FlashThoughtManager.h"
#import "DatabaseManager.h"
#import "LogManager.h"
#import <Foundation/Foundation.h>

NSString *textPreString =
    @"你好 ChatGPT! 今天是当前日期. "
    @"我希望你能成為我的筆記/"
    @"日記副駕駛。我在一天中的草稿日記中記錄了我的隨機想法、創意和事件等。 "
    @"這是我的草稿日記，以''''''''''''''''''''''''分隔：\n\
"
    @"''''''''''''''''''''''''\n";

NSString *textAfterString =
    @"\
"
    @"1. 注意不要遗留任何关键信息，重点是URL、时间等 \n"
    @" \
"
    @"2. 我给的想法 "
    @"基本是我将要做的事情，而不是已经完成的事情 \
"
    @"3. 請根據我筆記中提到的任務或者計劃創建一個可執行的待"
    @"辦事項清單。对于网站链接等重要信息需要放到详情描述"
    @"中。請使用第一人稱寫作，並且按照下面的JOSN格式創建"
    @"待辦事項清單 *in one code block*: \n\
{ \n\
"
    @"\"任務名\": \"任務詳細描述\", \
} \n\
\
"
    @"這是一個例子: \n\
{ \n\
    "
    @"\"開發AI語言學習軟件\": "
    @"\"我應該開始使用ChatGPT的API配合IOS的快捷指令功能開"
    @"發自己的AI語言學習軟件\",\n\
    \"投資特斯拉\": "
    @"\"在讀完Elon "
    @"Musk傳記之後，我應該仔細思考我對投資特斯拉的策略，"
    @"決定是否加大力度購買更多的股票\"\n\
}. \n\
3. "
    @"仅仅只输出给出答案（待辦事項清單JSON）内容，不要有任何"
    @"多余内容，这个非常非常重要！！！ \n";

NSString *audioPrompt =
    @"您好，Whisper "
    @"API！請把我的語音文件轉錄成文字。另外，我需要你為文字加標點符號。我是一"
    @"個multilingual speaker。非常感謝！ChatGPT";

@implementation FlashThought

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (instancetype)initWithType:(FlashThoughtType)type date:(NSDate *)date {
  self = [super init]; // 首先调用父类的init方法
  if (self) {
    _type = type;
    _date = date;
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.date forKey:@"date"];
  [coder encodeObject:self.content forKey:@"content"];
  [coder encodeObject:self.audioFileName forKey:@"audioFileName"];
  [coder encodeInteger:self.type forKey:@"type"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    _date = [coder decodeObjectOfClass:[NSDate class] forKey:@"date"];
    _audioFileName = [coder decodeObjectOfClass:[NSString class]
                                         forKey:@"audioFileName"];
    _type = [coder decodeIntegerForKey:@"type"];
    _content = [coder decodeObjectOfClass:[NSString class] forKey:@"content"];
  }
  return self;
}

@end

@interface FlashThoughtManager ()

@property(nonatomic, strong) NSMutableArray<FlashThought *> *thoughts;
@property(nonatomic, strong)
    NSMutableDictionary<NSNumber *, NSArray<FlashThought *> *>
        *gptTextToRemindersRequests;
@property(nonatomic, strong)
    NSMutableDictionary<NSNumber *, FlashThought *> *gptAudioToTextRequests;
@property(nonatomic, strong)
    NSMutableDictionary<NSNumber *, NSArray<FlashThought *> *>
        *gptAudioTextToRemindersRequests;

@property(assign) NSInteger countOfAllThoughts;
@property(assign) NSInteger countOfAudioThoughts;
@property(assign) NSInteger thoughtsHandled;

@end

@implementation FlashThoughtManager

+ (instancetype)sharedManager {
  static FlashThoughtManager *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
    sharedInstance.thoughts = [[NSMutableArray alloc] init];
    sharedInstance.delegates = [[NSMutableArray alloc] init];
    sharedInstance.gptTextToRemindersRequests =
        [[NSMutableDictionary alloc] init];
    sharedInstance.gptAudioToTextRequests = [[NSMutableDictionary alloc] init];
    sharedInstance.gptAudioTextToRemindersRequests =
        [[NSMutableDictionary alloc] init];
    sharedInstance.gptAudioToTextRequests = [[NSMutableDictionary alloc] init];
    [sharedInstance loadStoredThoughts];
    [GPTVisitor sharedInstance].delegate = sharedInstance;
    [ReminderManager sharedManager].delegate = sharedInstance;
    [[LoginService sharedService] addDelegate:sharedInstance];
  });

  return sharedInstance;
}

- (void)addExampleThoughts {
  {
    FlashThought *thought =
        [[FlashThought alloc] initWithType:FlashThoughtTypeTextFlashThought
                                      date:[NSDate date]];
    thought.content = @"处理问题: 微信反馈:观看的屏幕分享，画面很模糊...";
    [self addThought:thought];
  }

  {
    FlashThought *thought =
        [[FlashThought alloc] initWithType:FlashThoughtTypeTextFlashThought
                                      date:[NSDate date]];
    thought.content = @"Plan For Today";
    [self addThought:thought];
  }

  {
    FlashThought *thought =
        [[FlashThought alloc] initWithType:FlashThoughtTypeTextFlashThought
                                      date:[NSDate date]];
    thought.content = @"檢查亞馬遜帳號";
    [self addThought:thought];
  }

  {
    FlashThought *thought =
        [[FlashThought alloc] initWithType:FlashThoughtTypeTextFlashThought
                                      date:[NSDate date]];
    thought.content = @"给布丁梳毛. 并且要換洗被單";
    [self addThought:thought];
  }
}

- (void)dealWithAllDataReload:(NSData *)storedData {
  if (storedData) {
    [self.thoughts removeAllObjects];
    NSError *error = nil;
    NSSet *classes =
        [NSSet setWithObjects:[NSArray class], [FlashThought class], nil];
    NSArray *storedThoughts =
        [NSKeyedUnarchiver unarchivedObjectOfClasses:classes
                                            fromData:storedData
                                               error:&error];
    if (storedThoughts && !error) {
      [self.thoughts addObjectsFromArray:storedThoughts];
    } else {
      FLog(@"Failed to load thoughts: %@", error.localizedDescription);
    }

    for (id<FlashThoughtManagerDelegate> delegate in self.delegates) {
      if ([delegate respondsToSelector:@selector(shouldReloadData)]) {
        [delegate shouldReloadData];
      }
    }
  }
}

- (void)loadStoredThoughtsWithCompletion:(void (^)(void))completion {
  [[DatabaseManager sharedManager]
      loadAllDataWithCompletion:^(NSData *storedData) {
        [self dealWithAllDataReload:storedData];
        if (completion) {
          completion();
        }
  }];
}

- (void)loadStoredThoughts {
  [self loadStoredThoughtsWithCompletion:nil];

}

- (NSArray<FlashThought *> *)allThoughts {
  return [self.thoughts copy];
}

- (void)addThoughtInner:(FlashThought *)thought {
  [self.thoughts addObject:thought];
  [self saveThoughts];
  for (id<FlashThoughtManagerDelegate> delegate in self.delegates) {
    if ([delegate respondsToSelector:@selector(thoughtManagerDidAddThought:)]) {
      [delegate thoughtManagerDidAddThought:thought];
    }
  }
}

- (void)addThought:(FlashThought *)thought reload:(BOOL)reload {
  if (reload) {
    [self loadStoredThoughtsWithCompletion:^{
      [self addThoughtInner:thought];
    }];
  } else {
    [self addThoughtInner:thought];
  }
}

- (void)addThought:(FlashThought *)thought {
  [self addThought:thought reload:NO];
}

- (NSInteger)removeThought:(FlashThought *)thought {
  NSInteger index = NSNotFound;
  for (NSInteger i = 0; i < self.thoughts.count; ++i) {
    if ([self.thoughts[i].date isEqual:thought.date]) {
      index = i;
      break;
    }
  }

  if (index != NSNotFound) {
    if (thought.type != FlashThoughtTypeTextFlashThought) {
      NSURL *fileURL = [LogManager URLFromFileName:thought.audioFileName];
      NSError *error = nil;

      NSFileManager *fileManager = [NSFileManager defaultManager];
      //      assert([fileManager removeItemAtURL:fileURL error:&error]);
      // todo
      [fileManager removeItemAtURL:fileURL error:&error];
    }
    [self.thoughts removeObjectAtIndex:index];
    [self saveThoughts];
    for (id<FlashThoughtManagerDelegate> delegate in self.delegates) {
      if ([delegate respondsToSelector:@selector(thoughtManagerDidRemoveThought:)]) {
        [delegate thoughtManagerDidRemoveThought:thought];
      }
    }
  }

  return index;
}

- (void)updateThought:(FlashThought *)thought withContent:(NSString *)content {
  NSInteger index = NSNotFound;
  for (NSInteger i = 0; i < self.thoughts.count; ++i) {
    if ([self.thoughts[i].date isEqual:thought.date]) {
      index = i;
      break;
    }
  }
  assert((index != NSNotFound));
  if (index != NSNotFound) {
    FlashThought *existingThought = self.thoughts[index];
    existingThought.content = content;
    [self saveThoughts];
    for (id<FlashThoughtManagerDelegate> delegate in self.delegates) {
      if ([delegate respondsToSelector:@selector(thoughtManagerDidUpdateThought:)]) {
        [delegate thoughtManagerDidUpdateThought:thought];
      }
    }
  }
}

- (void)updateThought:(FlashThought *)thought
             withType:(FlashThoughtType)type
              content:(NSString *)content {
  NSInteger index = NSNotFound;
  for (NSInteger i = 0; i < self.thoughts.count; ++i) {
    if ([self.thoughts[i].date isEqual:thought.date]) {
      index = i;
      break;
    }
  }
  FLog(@"update updateThought");
  assert((index != NSNotFound));
  if (index != NSNotFound) {
    FLog(@"found index, update content '%@'", content);
    self.thoughts[index].content = content;
    self.thoughts[index].type = type;
    [self saveThoughts];
    
    for (id<FlashThoughtManagerDelegate> delegate in self.delegates) {
      if ([delegate respondsToSelector:@selector(thoughtManagerDidUpdateThought:)]) {
        [delegate thoughtManagerDidUpdateThought:thought];
      }
    }
  }
}

- (void)saveThoughts {
  NSError *error = nil;
  NSData *dataToStore =
      [NSKeyedArchiver archivedDataWithRootObject:self.thoughts
                            requiringSecureCoding:YES
                                            error:&error];
  if (dataToStore && !error) {
    [[DatabaseManager sharedManager] saveData:dataToStore];
  } else {
    FLog(@"Failed to save thoughts: %@", error.localizedDescription);
  }
}

- (void)checkAllThoughtDoneFrom:(NSString *)from {
  if (!self.isHandlingAllThoughts) {
    FLog(@"task been cancel");
    return;
  }

  FLog(@"checkAllThoughtDone from %@", from);
  if (self.thoughtsHandled == self.countOfAllThoughts) {
    FLog(@"done");
    self.isHandlingAllThoughts = NO;
    for (id<FlashThoughtManagerDelegate> delegate in self.delegates) {
      if ([delegate respondsToSelector:@selector(allThoughtsDidHandle)]) {
        [delegate allThoughtsDidHandle];
      }
    }
  }
}

- (void)cancelSendAllThoughtsToAI {
  self.isHandlingAllThoughts = NO;
}

- (BOOL)sendAllThoughtsToAI {
  assert(!self.isHandlingAllThoughts);

  NSArray<FlashThought *> *thoughts = [self allThoughts];
  if (thoughts.count == 0) {
    return NO;
  }

  self.countOfAllThoughts = thoughts.count;
  FLog(@"countOfAllThoughts = %d", (int)thoughts.count);
  self.countOfAudioThoughts = 0;
  self.thoughtsHandled = 0;
  self.isHandlingAllThoughts = YES;

  NSString *midString = @"";
  NSString *audioMidString = @"";
  NSMutableArray<FlashThought *> *textThoughts = [[NSMutableArray alloc] init];
  NSMutableArray<FlashThought *> *audioTextThoughts =
      [[NSMutableArray alloc] init];
  for (FlashThought *thought in thoughts) {
    if (thought.type == FlashThoughtTypeTextFlashThought) {
      [textThoughts addObject:thought];
      midString = [midString stringByAppendingString:thought.content];
      midString =
          [midString stringByAppendingString:@"\n''''''''''''''''''''''''\n"];
    } else if (thought.type == FlashThoughtTypeAudioFlashThought) {
      [self.gptAudioToTextRequests setObject:thought
                                      forKey:@(thought.audioFileName.hash)];
      self.countOfAudioThoughts++;
      [[GPTVisitor sharedInstance]
          visitGPTWithMessage:audioPrompt
                    messageId:thought.audioFileName.hash
                         file:[LogManager
                                  URLFromFileName:thought.audioFileName]];
    } else if (thought.type == FlashThoughtTypeAudioToTextFlashThought) {
      [audioTextThoughts addObject:thought];
      audioMidString = [audioMidString stringByAppendingString:thought.content];
      audioMidString = [audioMidString
          stringByAppendingString:@"\n''''''''''''''''''''''''\n"];
    }
  }

  if (textThoughts.count != 0) {
    NSString *prompt = [NSString
        stringWithFormat:@"%@%@%@", textPreString, midString, textAfterString];

    [self.gptTextToRemindersRequests setObject:textThoughts
                                        forKey:@(prompt.hash)];
    [[GPTVisitor sharedInstance] visitGPTWithMessage:prompt
                                           messageId:prompt.hash];
    for (id<FlashThoughtManagerDelegate> delegate in self.delegates) {
      if ([delegate respondsToSelector:@selector(thoughtsDidSentToAI:)]) {
        [delegate thoughtsDidSentToAI:textThoughts];
      }
    }
  }

  if (audioTextThoughts.count != 0) {
    NSString *prompt =
        [NSString stringWithFormat:@"%@%@%@", textPreString, audioMidString,
                                   textAfterString];

    [self.gptAudioTextToRemindersRequests setObject:audioTextThoughts
                                             forKey:@(prompt.hash)];
    [[GPTVisitor sharedInstance] visitGPTWithMessage:prompt
                                           messageId:prompt.hash];
    for (id<FlashThoughtManagerDelegate> delegate in self.delegates) {
      if ([delegate respondsToSelector:@selector(thoughtsDidSentToAI:)]) {
        [delegate thoughtsDidSentToAI:audioTextThoughts];
      }
    }
  }

  return YES;
}

- (void)visitor:(GPTVisitor *)visitor
    didVisitMessage:(NSString *)message
          messageId:(NSUInteger)messageId
       withResponse:(NSString *)response {
  FLog(@"GPT response: %@, messageId: %luld, message: %@", response,
       (unsigned long)messageId, message);

  FLog(@"=====GPT response: %@, messageId: %luld", response,
       (unsigned long)messageId);

  NSNumber *key = @(messageId);
  FLog(@"key: %@", key);
  if ([self.gptTextToRemindersRequests objectForKey:key] != nil ||
      [self.gptAudioTextToRemindersRequests objectForKey:key] != nil) {
    FLog(
        @"it is gptTextToRemindersRequests or gptAudioTextToRemindersRequests");
    [[ReminderManager sharedManager] addRemindersFromJsonString:response
                                                    toListNamed:@"FlashThought"
                                                         withID:messageId];
  } else if ([self.gptAudioToTextRequests objectForKey:key] != nil) {
    FLog(@"it is gptAudioToTextRequests");
    // get audio text
    FlashThought *thought = [self.gptAudioToTextRequests objectForKey:key];
    [self updateThought:thought
               withType:FlashThoughtTypeAudioToTextFlashThought
                content:response];

    FLog(@"self.gptAudioToTextRequests: %@", self.gptAudioToTextRequests);
    [self.gptAudioToTextRequests removeObjectForKey:key];

    if (self.gptAudioToTextRequests.count == 0) {
      FLog(@"self.gptAudioToTextRequests.count is 0");
      NSArray<FlashThought *> *thoughts = [self allThoughts];
      NSString *audioMidString = @"";
      NSMutableArray<FlashThought *> *audioTextThoughts =
          [[NSMutableArray alloc] init];
      for (FlashThought *thought in thoughts) {
        FLog(@"thought type: %ld", (long)thought.type);
        if (thought.type == FlashThoughtTypeAudioToTextFlashThought) {
          [audioTextThoughts addObject:thought];
          audioMidString =
              [audioMidString stringByAppendingString:thought.content];
          audioMidString = [audioMidString
              stringByAppendingString:@"\n''''''''''''''''''''''''\n"];

          FLog(@"-- add %@", thought.content);
        }
      }

      if (audioTextThoughts.count != 0) {
        NSString *prompt =
            [NSString stringWithFormat:@"%@%@%@", textPreString, audioMidString,
                                       textAfterString];

        [self.gptAudioTextToRemindersRequests setObject:audioTextThoughts
                                                 forKey:@(prompt.hash)];
        FLog(@"audioTextThoughts.count is not 0, visit GPT with json");
        [[GPTVisitor sharedInstance] visitGPTWithMessage:prompt
                                               messageId:prompt.hash];
        
        for (id<FlashThoughtManagerDelegate> delegate in self.delegates) {
          if ([delegate respondsToSelector:@selector(thoughtsDidSentToAI:)]) {
            [delegate thoughtsDidSentToAI:audioTextThoughts];
          }
        }
      }
    }
  }
  FLog(@"=====GPT response: %@, messageId: %luld", response,
       (unsigned long)messageId);
  [self checkAllThoughtDoneFrom:@"didVisitMessage"];
}

- (void)visitor:(GPTVisitor *)visitor
    didFailToVisitMessageWithMessageId:(NSUInteger)messageId
                                 error:(NSError *)error {
  if (error.code == NSURLErrorUnsupportedURL) {
    for (id<FlashThoughtManagerDelegate> delegate in self.delegates) {
      if ([delegate respondsToSelector:@selector(shouldStopHandlingThoughtsByError:)]) {
        [delegate shouldStopHandlingThoughtsByError:error];
      }
    }
  }
  NSNumber *key = @(messageId);
  FLog(@"didFailToVisitMessageWithMessageId: %ld, key: %@", messageId, key);
  if ([self.gptTextToRemindersRequests objectForKey:key] != nil) {
    FLog(@"it is gptTextToRemindersRequests");
    self.thoughtsHandled +=
        [self.gptTextToRemindersRequests objectForKey:key].count;
  } else if ([self.gptAudioTextToRemindersRequests objectForKey:key] != nil) {
    FLog(@"it is gptAudioTextToRemindersRequests");
    self.thoughtsHandled +=
        [self.gptAudioTextToRemindersRequests objectForKey:key].count;
  } else if ([self.gptAudioToTextRequests objectForKey:key] != nil) {
    FLog(@"it is gptAudioToTextRequests");
    // get audio text
    self.thoughtsHandled++;
  }
  [self.gptTextToRemindersRequests removeObjectForKey:key];
  [self.gptAudioToTextRequests removeObjectForKey:key];
  [self.gptAudioTextToRemindersRequests removeObjectForKey:key];
  [self checkAllThoughtDoneFrom:@"didFailToVisitMessageWithMessageId"];
}

- (void)didFinishAddingRemindersWithSuccess:(BOOL)success
                                      error:(NSError *)error
                                  messageID:(NSUInteger)messageID {
  NSNumber *key = @(messageID);
  FLog(@"key: %@, success: %d", key, success);
  if (success) {
    if ([self.gptTextToRemindersRequests objectForKey:key] != nil) {
      NSArray<FlashThought *> *thoughts =
          [self.gptTextToRemindersRequests objectForKey:key];
      for (id<FlashThoughtManagerDelegate> delegate in self.delegates) {
        if ([delegate respondsToSelector:@selector(thoughtsDidSaveToReminders:)]) {
          [delegate thoughtsDidSaveToReminders:thoughts];
        }
      }
      self.thoughtsHandled += thoughts.count;
      FLog(@"thoughtsHandled1 += %d", (int)thoughts.count);
    }
    if ([self.gptAudioTextToRemindersRequests objectForKey:key] != nil) {
      NSArray<FlashThought *> *thoughts =
          [self.gptAudioTextToRemindersRequests objectForKey:key];
      for (id<FlashThoughtManagerDelegate> delegate in self.delegates) {
        if ([delegate respondsToSelector:@selector(thoughtsDidSaveToReminders:)]) {
          [delegate thoughtsDidSaveToReminders:thoughts];
        }
      }
      self.thoughtsHandled += thoughts.count;
      FLog(@"thoughtsHandled2 += %d", (int)thoughts.count);
    }
  }
  [self.gptTextToRemindersRequests removeObjectForKey:key];
  [self.gptAudioTextToRemindersRequests removeObjectForKey:key];

  [self checkAllThoughtDoneFrom:@"didFinishAddingRemindersWithSuccess"];
}

- (void)onSignInSuccess {
  [self loadStoredThoughts];
  [[DatabaseManager sharedManager]
      observeUserBase64DataWithCompletion:^(NSData *data) {
        [self dealWithAllDataReload:data];
      }];
}

- (void)onSignInFailed {
  [self loadStoredThoughts];
}

- (void)onSignOutSuccess {
  [self loadStoredThoughts];
}

- (void)addDelegate:(id<FlashThoughtManagerDelegate>)delegate {
  if (![self.delegates containsObject:delegate]) {
    [self.delegates addObject:delegate];
  }
}

- (void)removeDelegate:(id<FlashThoughtManagerDelegate>)delegate {
  [self.delegates removeObject:delegate];
}

@end
