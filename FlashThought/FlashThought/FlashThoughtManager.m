//
//  FlashThoughtManager.m
//  FlashThoughts
//
//  Created by tim on 2024/3/27.
//

#import "FlashThoughtManager.h"
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
''''''''''''''''''''''''\n\
"
    @"1. 注意不要遗留任何关键信息，重点是URL、时间等 "
    @" \
"
    @"2.我给的想法 "
    @"基本是我将要做的事情，而不是已经完成的事情 \
"
    @"3."
    @"請根據我筆記中提到的任務或者計劃創建一個可執行的待"
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

+ (NSURL *)audioRecordingURLFromFileName:(NSString *)fileName {
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                       NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths objectAtIndex:0];
  NSString *filePath =
      [documentsDirectory stringByAppendingPathComponent:fileName];

  return [NSURL fileURLWithPath:filePath];
}

+ (instancetype)sharedManager {
  static FlashThoughtManager *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
    sharedInstance.thoughts = [[NSMutableArray alloc] init];
    sharedInstance.gptTextToRemindersRequests =
        [[NSMutableDictionary alloc] init];
    sharedInstance.gptAudioToTextRequests = [[NSMutableDictionary alloc] init];
    sharedInstance.gptAudioTextToRemindersRequests =
        [[NSMutableDictionary alloc] init];
    sharedInstance.gptAudioToTextRequests = [[NSMutableDictionary alloc] init];
    [sharedInstance loadStoredThoughts];
  });
  [GPTVisitor sharedInstance].delegate = sharedInstance;
  [ReminderManager sharedManager].delegate = sharedInstance;
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

- (void)loadStoredThoughts {
  [self.thoughts removeAllObjects];
  NSUserDefaults *sharedDefaults =
      [[NSUserDefaults alloc] initWithSuiteName:APP_GROUP_NAME];
  NSData *storedData = [sharedDefaults objectForKey:@"FlashThoughts"];
  if (storedData) {
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
      NSLog(@"Failed to load thoughts: %@", error.localizedDescription);
    }
  }

  //  [self addExampleThoughts];
}

- (NSArray<FlashThought *> *)allThoughts {
  return [self.thoughts copy];
}

- (void)addThought:(FlashThought *)thought {
  [self.thoughts addObject:thought];
  [self saveThoughts];
  [self.delegate thoughtManagerDidAddThought:thought];
}

- (NSInteger)removeThought:(FlashThought *)thought {
  NSInteger index = [self.thoughts indexOfObject:thought];

  if (index != NSNotFound) {
    NSURL *fileURL = [FlashThoughtManager audioRecordingURLFromFileName:thought.audioFileName];
    NSError *error = nil;

    NSFileManager *fileManager = [NSFileManager defaultManager];
    assert([fileManager removeItemAtURL:fileURL error:&error]);
    
    [self.thoughts removeObjectAtIndex:index];
    [self saveThoughts];
    [self.delegate thoughtManagerDidRemoveThought:thought];
  }

  return index;
}

- (void)updateThought:(FlashThought *)thought withContent:(NSString *)content {
  NSUInteger index = [self.thoughts indexOfObject:thought];
  if (index != NSNotFound) {
    FlashThought *existingThought = self.thoughts[index];
    existingThought.content = content;
    [self saveThoughts];
    [self.delegate thoughtManagerDidUpdateThought:existingThought];
  }
}

- (void)updateThought:(FlashThought *)thought
             withType:(FlashThoughtType)type
              content:(NSString *)content {
  NSUInteger index = [self.thoughts indexOfObject:thought];
  if (index != NSNotFound) {
    FlashThought *existingThought = self.thoughts[index];
    existingThought.content = content;
    existingThought.type = type;
    [self saveThoughts];
    [self.delegate thoughtManagerDidUpdateThought:existingThought];
  }
}

- (void)saveThoughts {
  NSError *error = nil;
  NSData *dataToStore =
      [NSKeyedArchiver archivedDataWithRootObject:self.thoughts
                            requiringSecureCoding:YES
                                            error:&error];
  if (dataToStore && !error) {
    NSUserDefaults *defaults =
        [[NSUserDefaults alloc] initWithSuiteName:APP_GROUP_NAME];
    [defaults setObject:dataToStore forKey:@"FlashThoughts"];
    [defaults synchronize];
  } else {
    NSLog(@"Failed to save thoughts: %@", error.localizedDescription);
  }
}

- (void)checkAllThoughtDone {
  if (!self.isHandlingAllThoughts) {
    NSLog(@"task been cancel");
    return;
  }

  if (self.thoughtsHandled == self.countOfAllThoughts) {
    self.isHandlingAllThoughts = NO;
    [self.delegate allThoughtsDidHandle];
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
  NSLog(@"countOfAllThoughts = %d", (int)thoughts.count);
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
                         file:[FlashThoughtManager
                                  audioRecordingURLFromFileName:
                                      thought.audioFileName]];
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
    [self.delegate thoughtsDidSentToAI:textThoughts];
  }

  if (audioTextThoughts.count != 0) {
    NSString *prompt =
        [NSString stringWithFormat:@"%@%@%@", textPreString, audioMidString,
                                   textAfterString];

    [self.gptAudioTextToRemindersRequests setObject:audioTextThoughts
                                             forKey:@(prompt.hash)];
    [[GPTVisitor sharedInstance] visitGPTWithMessage:prompt
                                           messageId:prompt.hash];
    [self.delegate thoughtsDidSentToAI:audioTextThoughts];
  }

  return YES;
}

- (void)visitor:(GPTVisitor *)visitor
    didVisitMessage:(NSString *)message
          messageId:(NSUInteger)messageId
       withResponse:(NSString *)response {
  NSLog(@"GPT response: %@", response);

  NSNumber *key = @(messageId);
  if ([self.gptTextToRemindersRequests objectForKey:key] != nil ||
      [self.gptAudioTextToRemindersRequests objectForKey:key] != nil) {
    [[ReminderManager sharedManager] addRemindersFromJsonString:response
                                                    toListNamed:@"FlashThought"
                                                         withID:messageId];
  } else if ([self.gptAudioToTextRequests objectForKey:key] != nil) {
    // get audio text
    FlashThought *thought = [self.gptAudioToTextRequests objectForKey:key];
    [self updateThought:thought
               withType:FlashThoughtTypeAudioToTextFlashThought
                content:response];
    [self.gptAudioToTextRequests removeObjectForKey:key];

    if (self.gptAudioToTextRequests.count == 0) {
      NSArray<FlashThought *> *thoughts = [self allThoughts];
      NSString *audioMidString = @"";
      NSMutableArray<FlashThought *> *audioTextThoughts =
          [[NSMutableArray alloc] init];
      for (FlashThought *thought in thoughts) {
        if (thought.type == FlashThoughtTypeAudioToTextFlashThought) {
          [audioTextThoughts addObject:thought];
          audioMidString =
              [audioMidString stringByAppendingString:thought.content];
          audioMidString = [audioMidString
              stringByAppendingString:@"\n''''''''''''''''''''''''\n"];
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
        [self.delegate thoughtsDidSentToAI:audioTextThoughts];
      }
    }
  }
  [self checkAllThoughtDone];
}

- (void)visitor:(GPTVisitor *)visitor
    didFailToVisitMessageWithMessageId:(NSUInteger)messageId
                                 error:(NSError *)error {
  if (error.code == NSURLErrorUnsupportedURL) {
    [self.delegate shouldStopHandlingThoughtsByError:error];
  }
  NSNumber *key = @(messageId);
  if ([self.gptTextToRemindersRequests objectForKey:key] != nil) {
    self.thoughtsHandled +=
        [self.gptTextToRemindersRequests objectForKey:key].count;
  } else if ([self.gptAudioTextToRemindersRequests objectForKey:key] != nil) {
    self.thoughtsHandled +=
        [self.gptAudioTextToRemindersRequests objectForKey:key].count;
  } else if ([self.gptAudioToTextRequests objectForKey:key] != nil) {
    // get audio text
    self.thoughtsHandled++;
  }
  [self.gptTextToRemindersRequests removeObjectForKey:key];
  [self.gptAudioToTextRequests removeObjectForKey:key];
  [self.gptAudioTextToRemindersRequests removeObjectForKey:key];
  [self checkAllThoughtDone];
}

- (void)didFinishAddingRemindersWithSuccess:(BOOL)success
                                      error:(NSError *)error
                                  messageID:(NSUInteger)messageID {
  NSNumber *key = @(messageID);
  if (success) {
    if ([self.gptTextToRemindersRequests objectForKey:key] != nil) {
      NSArray<FlashThought *> *thoughts =
          [self.gptTextToRemindersRequests objectForKey:key];
      [self.delegate thoughtsDidSaveToReminders:thoughts];
      self.thoughtsHandled += thoughts.count;
      NSLog(@"thoughtsHandled1 += %d", (int)thoughts.count);
    }
    if ([self.gptAudioTextToRemindersRequests objectForKey:key] != nil) {
      NSArray<FlashThought *> *thoughts =
          [self.gptAudioTextToRemindersRequests objectForKey:key];
      [self.delegate thoughtsDidSaveToReminders:thoughts];
      self.thoughtsHandled += thoughts.count;
      NSLog(@"thoughtsHandled2 += %d", (int)thoughts.count);
    }
  }
  [self.gptTextToRemindersRequests removeObjectForKey:key];
  [self.gptAudioTextToRemindersRequests removeObjectForKey:key];

  [self checkAllThoughtDone];
}

@end
