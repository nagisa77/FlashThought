//
//  NewFlashThoughtWindowController.m
//  FlashThoughtsMacOS
//
//  Created by 陈嘉挺 on 2024/4/8.
//

#import "NewFlashThoughtWindowController.h"
#import <FlashThoughtPlatform/FlashThoughtManager.h>
#import <FlashThoughtPlatform/LogManager.h>

@interface NewFlashThoughtWindowController ()

@property IBOutlet NSTextField *textField;

@end

@implementation NewFlashThoughtWindowController

- (void)awakeFromNib {
}

- (IBAction)cancelDidClicked:(id)sender {
  [self close];
}

- (IBAction)confirmDidClicked:(id)sender {
  if (![self.textField.stringValue isEqual:@""]) {
    FlashThought *fs =
        [[FlashThought alloc] initWithType:FlashThoughtTypeTextFlashThought
                                      date:[NSDate date]];
    fs.content = self.textField.stringValue;
    FLog(@"add a flash thought %@", fs.content);
    [[FlashThoughtManager sharedManager] addThought:fs];
  }
  [self close];
}

- (void)close {
  [super close];
}

@end
