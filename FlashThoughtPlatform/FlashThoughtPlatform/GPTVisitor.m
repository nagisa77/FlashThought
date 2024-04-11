//
//  GPTVisitor.m
//  FlashThoughts
//
//  Created by tim on 2024/3/28.
//

#import "DatabaseManager.h"
#import <Firebase/Firebase.h>
#import <FlashThoughtPlatform/GPTVisitor.h>
#import <FlashThoughtPlatform/LogManager.h>
#import <Foundation/Foundation.h>

@interface GPTVisitor ()
@property(strong) NSString *apiKey;
@property(strong) NSString *host;
@end

@implementation GPTVisitor

+ (instancetype)sharedInstance {
  static GPTVisitor *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];

    [[DatabaseManager sharedManager]
        observeUserAPIKeyCompletion:^(NSString *apikey) {
          sharedInstance.apiKey = apikey;
        }];
    [[DatabaseManager sharedManager]
        observeUserHostWithCompletion:^(NSString *host) {
          sharedInstance.host = host;
        }];
  });
  return sharedInstance;
}

- (NSString *)getAPIKey {
  return self.apiKey;
}

- (void)updateAPIKey:(NSString *)apiKey {
  self.apiKey = apiKey;
  [[DatabaseManager sharedManager] saveAPIKey:apiKey];
}

- (NSString *)getProxyHost {
  if (self.host == nil || [self.host isEqual:@""]) {
    return @"https://api.openai.com/";
  }
  return self.host;
}

- (void)updateProxyHost:(NSString *)proxy {
  self.host = proxy;
  [[DatabaseManager sharedManager] saveHost:proxy];
}

- (void)visitGPTWithMessage:(NSString *)message
                  messageId:(NSUInteger)messageId {
  NSString *const openAIURL =
      [NSString stringWithFormat:@"%@/v1/chat/completions",
                                 [[GPTVisitor sharedInstance] getProxyHost]];
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
  [request setURL:[NSURL URLWithString:openAIURL]];
  [request setHTTPMethod:@"POST"];
  [request setValue:[NSString stringWithFormat:@"Bearer %@", [self getAPIKey]]
      forHTTPHeaderField:@"Authorization"];
  [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

  NSDictionary *bodyData = @{
    // todo: 给用户选择
    @"model" : @"gpt-4",
    @"messages" : @[
      @{
        @"role" : @"user",
        @"content" : message,
      },
    ],
    @"temperature" : @0,
  };

  NSError *error;
  NSData *postData = [NSJSONSerialization dataWithJSONObject:bodyData
                                                     options:0
                                                       error:&error];
  [request setHTTPBody:postData];

  NSURLSessionConfiguration *configuration =
      [NSURLSessionConfiguration defaultSessionConfiguration];
  configuration.timeoutIntervalForRequest = 120; // API太垃圾，准备等待久一点
  NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
  NSURLSessionDataTask *dataTask = [session
      dataTaskWithRequest:request
        completionHandler:^(NSData *data, NSURLResponse *response,
                            NSError *error) {
          if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
              [self.delegate visitor:self
                  didFailToVisitMessageWithMessageId:messageId
                                               error:error];
            });
          } else {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            FLog(@"Response status code: %ld", (long)[httpResponse statusCode]);

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

              dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate visitor:self
                       didVisitMessage:message
                             messageId:messageId
                          withResponse:content];
              });
            } else {
              dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate visitor:self
                    didFailToVisitMessageWithMessageId:messageId
                                                 error:parseError];
              });
            }
          }
        }];

  [dataTask resume];
}
- (void)visitGPTWithMessage:(NSString *)message
                  messageId:(NSUInteger)messageId
                       file:(NSURL *)fileURL {
  NSString *const openAIURL =
      [NSString stringWithFormat:@"%@/v1/audio/transcriptions",
                                 [[GPTVisitor sharedInstance] getProxyHost]];

  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
  [request setURL:[NSURL URLWithString:openAIURL]];
  [request setHTTPMethod:@"POST"];

  // 设置认证头和内容类型头
  [request setValue:[NSString stringWithFormat:@"Bearer %@", [self getAPIKey]]
      forHTTPHeaderField:@"Authorization"];
  NSString *boundary = @"UniqueBoundary12345";
  [request setValue:[NSString
                        stringWithFormat:@"multipart/form-data; boundary=%@",
                                         boundary]
      forHTTPHeaderField:@"Content-Type"];

  NSMutableData *body = [NSMutableData data];

  // 添加文本字段
  [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary]
                       dataUsingEncoding:NSUTF8StringEncoding]];
  [body appendData:[@"Content-Disposition: form-data; name=\"model\"\r\n\r\n"
                       dataUsingEncoding:NSUTF8StringEncoding]];
  [body appendData:[@"whisper-1\r\n" dataUsingEncoding:NSUTF8StringEncoding]];

  [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary]
                       dataUsingEncoding:NSUTF8StringEncoding]];
  [body appendData:[@"Content-Disposition: form-data; name=\"prompt\"\r\n\r\n"
                       dataUsingEncoding:NSUTF8StringEncoding]];
  [body appendData:[[NSString stringWithFormat:@"%@\r\n", message]
                       dataUsingEncoding:NSUTF8StringEncoding]];

  // 添加文件
  NSError *error = nil;
  NSData *fileData = [NSData dataWithContentsOfURL:fileURL
                                           options:0
                                             error:&error];
  if (fileData != nil) {
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary]
                         dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString
                         stringWithFormat:@"Content-Disposition: form-data; "
                                          @"name=\"file\"; filename=\"%@\"\r\n",
                                          [fileURL lastPathComponent]]
                         dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n"
                         dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:fileData];
    [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
  } else {
    FLog(@"Error reading file: %@", error);
    return;
  }

  // 结束边界
  [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary]
                       dataUsingEncoding:NSUTF8StringEncoding]];

  [request setHTTPBody:body];

  // 发送请求
  NSURLSession *session = [NSURLSession sharedSession];
  NSURLSessionDataTask *dataTask = [session
      dataTaskWithRequest:request
        completionHandler:^(NSData *data, NSURLResponse *response,
                            NSError *error) {
          if (error) {
            FLog(@"Error: %@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
              [self.delegate visitor:self
                  didFailToVisitMessageWithMessageId:messageId
                                               error:error];
            });

          } else {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if ([httpResponse statusCode] == 200) {
              NSError *parseError = nil;
              NSDictionary *responseDictionary =
                  [NSJSONSerialization JSONObjectWithData:data
                                                  options:0
                                                    error:&parseError];
              // 处理响应
              NSString *transcription = responseDictionary[@"text"];
              dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate visitor:self
                       didVisitMessage:message
                             messageId:messageId
                          withResponse:transcription];
              });
            } else {
              FLog(@"Server responded with status code: %ld",
                   (long)[httpResponse statusCode]);
              dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate visitor:self
                    didFailToVisitMessageWithMessageId:messageId
                                                 error:error];
              });
            }
          }
        }];
  [dataTask resume];
}

@end
