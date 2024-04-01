//
//  FlashThoughtManager.m
//  FlashThoughts
//
//  Created by tim on 2024/3/27.
//

#import "FlashThoughtManager.h"
#import <Foundation/Foundation.h>

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
    _audioFileName = [coder decodeObjectOfClass:[NSString class] forKey:@"audioFileName"];
    _type = [coder decodeIntegerForKey:@"type"];
    _content = [coder decodeObjectOfClass:[NSString class] forKey:@"content"];
  }
  return self;
}

@end

@interface FlashThoughtManager ()

@property(nonatomic, strong) NSMutableArray<FlashThought *> *thoughts;
@property(nonatomic, strong)
    NSMutableDictionary<NSNumber *, NSArray<FlashThought *> *> *gptRequests;

@property(assign) NSInteger thoughtsLeft;
@property(assign) BOOL isHandlingAllThoughts;

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
    sharedInstance.gptRequests = [[NSMutableDictionary alloc] init];
    [sharedInstance loadStoredThoughts];
  });
  // todo: more than one register
  [GPTVisitor sharedInstance].delegate = sharedInstance;
  [ReminderManager sharedManager].delegate = sharedInstance;
  return sharedInstance;
}

- (void)loadStoredThoughts {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSData *storedData = [defaults objectForKey:@"FlashThoughts"];
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

- (void)saveThoughts {
  NSError *error = nil;
  NSData *dataToStore =
      [NSKeyedArchiver archivedDataWithRootObject:self.thoughts
                            requiringSecureCoding:YES
                                            error:&error];
  if (dataToStore && !error) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:dataToStore forKey:@"FlashThoughts"];
    [defaults synchronize];
  } else {
    NSLog(@"Failed to save thoughts: %@", error.localizedDescription);
  }
}

- (void)consumptionThought:(NSInteger)numsOfThought {
  assert(numsOfThought <= self.thoughtsLeft && self.isHandlingAllThoughts);

  self.thoughtsLeft -= numsOfThought;
  if (self.thoughtsLeft == 0) {
    self.isHandlingAllThoughts = NO;
    [self.delegate allThoughtsDidHandle];
  }
}

- (BOOL)sendAllThoughtsToAI {
  assert(!self.isHandlingAllThoughts);

  NSString *preString =
      @"你好 ChatGPT! 今天是当前日期. "
      @"我希望你能成為我的筆記/"
      @"日記副駕駛。我在一天中的草稿日記中記錄了我的隨機想法、創意和事件等。 "
      @"這是我的草稿日記，以''''''''''''''''''''''''分隔：\n\
  "
      @"''''''''''''''''''''''''\n";
  NSString *afterString =
      @"\
  ''''''''''''''''''''''''\n\
  "
      @"現在請你幫我執行以下任務: \
  1.  "
      @"收集我輸入的全部想法和筆記，根據它們寫一份完整的筆"
      @"記。這個新版本的筆記要有更合理的格式和邏輯結構，有"
      @"更好的寫作風格，但是不改變之前筆記和想法的原意。請"
      @"使用第一人稱寫作。 請確保不要遺漏任何細節。\
  "
      @"2.對筆記做一份詳細的摘要。請不要遺漏任何重點。\
 "
      @" "
      @"3.我给的想法 "
      @"基本是我将要做的事情，而不是已经完成的事情 \
  "
      @"4."
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
  5. "
      @"仅仅只输出给出答案（待辦事項清單）内容，不要有任何"
      @"多余内容，这个非常非常重要！！！ \n";

  NSArray<FlashThought *> *thoughts = [self allThoughts];

  if (thoughts.count == 0) {
    return NO;
  }

  self.thoughtsLeft = thoughts.count;
  self.isHandlingAllThoughts = YES;

  NSString *midString = @"";
  for (FlashThought *thought in thoughts) {
    midString = [midString stringByAppendingString:thought.content];
    midString =
        [midString stringByAppendingString:@"\n''''''''''''''''''''''''\n"];
  }

  NSString *prompt =
      [NSString stringWithFormat:@"%@%@%@", preString, midString, afterString];

  [self.gptRequests setObject:thoughts forKey:@(prompt.hash)];
  [[GPTVisitor sharedInstance] visitGPTWithMessage:prompt
                                         messageId:prompt.hash];
  [self.delegate thoughtsDidSentToAI:thoughts];

  return YES;
}

- (void)visitor:(GPTVisitor *)visitor
    didVisitMessage:(NSString *)message
          messageId:(NSUInteger)messageId
       withResponse:(NSString *)response {
  NSLog(@"GPT response: %@", response);

  [[ReminderManager sharedManager] addRemindersFromJsonString:response
                                                  toListNamed:@"FlashThought"
                                                       withID:messageId];
}

- (void)visitor:(GPTVisitor *)visitor
    didFailToVisitMessageWithMessageId:(NSUInteger)messageId
                                 error:(NSError *)error {
  assert(visitor == self);
  NSNumber *key = @(messageId);
  NSArray<FlashThought *> *thoughts = [self.gptRequests objectForKey:key];

  [self consumptionThought:thoughts.count];
}

- (void)didFinishAddingRemindersWithSuccess:(BOOL)success
                                      error:(NSError *)error
                                  messageID:(NSUInteger)messageID {
  NSNumber *key = @(messageID);
  NSArray<FlashThought *> *thoughts = [self.gptRequests objectForKey:key];

  [self consumptionThought:thoughts.count];
  if (success) {
    [self.delegate thoughtsDidSaveToReminders:thoughts];
  }
}

@end
