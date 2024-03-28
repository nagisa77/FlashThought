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

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.date forKey:@"date"];
  [coder encodeObject:self.content forKey:@"content"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  if ((self = [super init])) {
    _date = [coder decodeObjectOfClass:[NSDate class] forKey:@"date"];
    _content = [coder decodeObjectOfClass:[NSString class] forKey:@"content"];
  }
  return self;
}

@end

@interface FlashThoughtManager ()

@property(nonatomic, strong) NSMutableArray<FlashThought *> *thoughts;

@end

@implementation FlashThoughtManager

+ (instancetype)sharedManager {
  static FlashThoughtManager *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
    sharedInstance.thoughts = [[NSMutableArray alloc] init];
    [sharedInstance loadStoredThoughts];
  });
  [GPTVisitor sharedInstance].delegate = sharedInstance;
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

- (void)removeThought:(FlashThought *)thought {
  [self.thoughts removeObject:thought];
  [self saveThoughts];
  [self.delegate thoughtManagerDidRemoveThought:thought];
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

- (void)sendAllThoughtsToAI {
  NSString* preString = @"你好 ChatGPT! 今天是当前日期. 我希望你能成為我的筆記/日記副駕駛。我在一天中的草稿日記中記錄了我的隨機想法、創意和事件等。 這是我的草稿日記，以''''''''''''''''''''''''分隔：\n\
  ''''''''''''''''''''''''\n";
  NSString* afterString = @"\
  ''''''''''''''''''''''''\n\
  現在請你幫我執行以下任務: \
  1.  收集我輸入的全部想法和筆記，根據它們寫一份完整的筆記。這個新版本的筆記要有更合理的格式和邏輯結構，有更好的寫作風格，但是不改變之前筆記和想法的原意。請使用第一人稱寫作。 請確保不要遺漏任何細節。\
  2.對筆記做一份詳細的摘要。請不要遺漏任何重點。\
  3.我给的想法 基本是我将要做的事情，而不是已经完成的事情 \
  4.請根據我筆記中提到的任務或者計劃創建一個可執行的待辦事項清單。对于网站链接等重要信息需要放到详情描述中。請使用第一人稱寫作，並且按照下面的JOSN格式創建待辦事項清單 *in one code block*: \n\
  { \n\
  \"任務名\": \"任務詳細描述\", \
  } \n\
 \
  這是一個例子: \n\
  { \n\
      \"開發AI語言學習軟件\": \"我應該開始使用ChatGPT的API配合IOS的快捷指令功能開發自己的AI語言學習軟件\",\n\
      \"投資特斯拉\": \"在讀完Elon Musk傳記之後，我應該仔細思考我對投資特斯拉的策略，決定是否加大力度購買更多的股票\"\n\
  }. \n\
  5. 仅仅只输出给出答案（待辦事項清單）内容，不要有任何多余内容，这个非常非常重要！！！ \n";
  
  NSArray<FlashThought *> *thoughts = [self allThoughts];
  NSString *midString = @"";
  for (FlashThought *thought in thoughts) {
    midString = [midString stringByAppendingString:thought.content];
    midString = [midString stringByAppendingString:@"\n''''''''''''''''''''''''\n"];
  }
  
  NSString *prompt = [NSString stringWithFormat:@"%@%@%@", preString, midString, afterString];
  [[GPTVisitor sharedInstance] visitGPTWithMessage:prompt messageId:prompt.hash];
}

- (void)visitor:(GPTVisitor *)visitor
    didVisitMessage:(NSString *)message
          messageId:(NSInteger)messageId
   withResponse:(NSString *)response {
  NSLog(@"GPT response: %@", response);
}

- (void)visitor:(GPTVisitor *)visitor
    didFailToVisitMessageWithMessageId:(NSInteger)messageId
          error:(NSError *)error {
  
}

@end
