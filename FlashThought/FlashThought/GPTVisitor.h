//
//  GPTVisitor.h
//  FlashThoughts
//
//  Created by tim on 2024/3/28.
//

#ifndef GPTVisitor_h
#define GPTVisitor_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define APP_GROUP_NAME @"group.tim.flashThoughts"

@protocol GPTVisitorDelegate;

@interface GPTVisitor : NSObject

@property(nonatomic, weak) id<GPTVisitorDelegate> delegate;

+ (instancetype)sharedInstance;

- (NSString *)getAPIKey;

- (NSString *)getProxyHost;

- (void)updateProxyHost:(NSString *)proxy;

- (void)updateAPIKey:(NSString *)apiKey;

- (void)visitGPTWithMessage:(NSString *)message messageId:(NSUInteger)messageId;

- (void)visitGPTWithMessage:(NSString *)message
                  messageId:(NSUInteger)messageId
                       file:(NSURL *)fileURL;

@end

@protocol GPTVisitorDelegate <NSObject>
@optional
- (void)visitor:(GPTVisitor *)visitor
    didVisitMessage:(NSString *)message
          messageId:(NSUInteger)messageId
       withResponse:(NSString *)response;
- (void)visitor:(GPTVisitor *)visitor
    didFailToVisitMessageWithMessageId:(NSUInteger)messageId
                                 error:(NSError *)error;
@end

#endif /* GPTVisitor_h */
