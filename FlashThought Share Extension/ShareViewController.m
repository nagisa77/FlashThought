//
//  ShareViewController.m
//  FlashThought Share Extension
//
//  Created by tim on 2024/4/2.
//

#import "ShareViewController.h"
#import <FlashThought/FlashThoughtManager.h>

@interface ShareViewController ()

@end

@implementation ShareViewController

- (BOOL)isContentValid {
    // Do validation of contentText and/or NSExtensionContext attachments here
    return YES;
}

- (void)didSelectPost {
  NSString *textToShare = self.contentText;
  [[FlashThoughtManager sharedManager] loadStoredThoughts];

  FlashThought* flashThought = [[FlashThought alloc] initWithType:FlashThoughtTypeTextFlashThought date:[NSDate date]];
  flashThought.content = textToShare;
  [[FlashThoughtManager sharedManager] addThought:flashThought];
  
  [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
}

- (NSArray *)configurationItems {
    // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
    return @[];
}

@end
