//
//  GPTVisitor.m
//  FlashThoughts
//
//  Created by tim on 2024/3/28.
//

#import "GPTVisitor.h"
#import <Foundation/Foundation.h>

@implementation GPTVisitor

+ (instancetype)sharedInstance {
  static GPTVisitor *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

- (void)visitGPTWithMessage:(NSString *)message messageId:(NSInteger)messageId {
  NSString *const openAIURL = @"https://api.openai.com/v1/chat/completions";
  // todo: set to config
  NSString *const apiKey =
      @"";

  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
  [request setURL:[NSURL URLWithString:openAIURL]];
  [request setHTTPMethod:@"POST"];
  [request setValue:[NSString stringWithFormat:@"Bearer %@", apiKey]
      forHTTPHeaderField:@"Authorization"];
  [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

  NSDictionary *bodyData = @{
    @"model" : @"gpt-3.5-turbo",
    @"messages" : @[
      @{
        @"role" : @"user",
        @"content" : message,
      },
    ],
    @"temperature" : @0.5,
  };

  NSError *error;
  NSData *postData = [NSJSONSerialization dataWithJSONObject:bodyData
                                                     options:0
                                                       error:&error];
  [request setHTTPBody:postData];

  // 发送请求
  NSURLSession *session = [NSURLSession sharedSession];
  NSURLSessionDataTask *dataTask = [session
      dataTaskWithRequest:request
        completionHandler:^(NSData *data, NSURLResponse *response,
                            NSError *error) {
          if (error) {
            NSLog(@"Error: %@", error);
          } else {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            NSLog(@"Response status code: %ld",
                  (long)[httpResponse statusCode]);

            NSError *parseError = nil;
            NSDictionary *responseDictionary =
                [NSJSONSerialization JSONObjectWithData:data
                                                options:0
                                                  error:&parseError];
            NSDictionary *responseDict = (NSDictionary *)responseDictionary;
            NSArray *choices = responseDict[@"choices"];
            if (choices.count > 0) {
              NSDictionary *firstChoice = choices[0];
              NSDictionary *msg = firstChoice[@"message"];
              NSString *content = msg[@"content"];

              [self.delegate visitor:self
                     didVisitMessage:message
                           messageId:messageId
                        withResponse:content];
            } else {
              [self.delegate visitor:self
                  didFailToVisitMessageWithMessageId:messageId
                                               error:error];
            }
          }
        }];

  [dataTask resume];
}

@end
