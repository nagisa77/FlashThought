//
//  NewFlashThoughtWindowController.m
//  FlashThoughtsMacOS
//
//  Created by 陈嘉挺 on 2024/4/8.
//

#import "NewFlashThoughtWindowController.h"
#import <FlashThoughtPlatform/FlashThoughtManager.h>
#import <FlashThoughtPlatform/LogManager.h>
#import <Cocoa/Cocoa.h>

@interface EditableNSTextField : NSTextField
@end

@implementation EditableNSTextField

- (BOOL)performKeyEquivalent:(NSEvent *)event {
    NSUInteger commandKey = NSEventModifierFlagCommand;
    NSUInteger commandShiftKey = NSEventModifierFlagCommand | NSEventModifierFlagShift;

    if (event.type == NSEventTypeKeyDown) {
        NSUInteger modifierFlags = [event modifierFlags] & NSEventModifierFlagDeviceIndependentFlagsMask;

        if (modifierFlags == commandKey) {
            NSString *key = [event charactersIgnoringModifiers];
            if ([key isEqualToString:@"x"]) {
                if ([NSApp sendAction:@selector(cut:) to:nil from:self]) return YES;
            } else if ([key isEqualToString:@"c"]) {
                if ([NSApp sendAction:@selector(copy:) to:nil from:self]) return YES;
            } else if ([key isEqualToString:@"v"]) {
                if ([NSApp sendAction:@selector(paste:) to:nil from:self]) return YES;
            } else if ([key isEqualToString:@"z"]) {
                if ([NSApp sendAction:NSSelectorFromString(@"undo:") to:nil from:self]) return YES;
            } else if ([key isEqualToString:@"a"]) {
                if ([NSApp sendAction:@selector(selectAll:) to:nil from:self]) return YES;
            }
        } else if (modifierFlags == commandShiftKey) {
            NSString *key = [event charactersIgnoringModifiers];
            if ([key isEqualToString:@"Z"]) {
                if ([NSApp sendAction:NSSelectorFromString(@"redo:") to:nil from:self]) return YES;
            }
        }
    }
    return [super performKeyEquivalent:event];
}
@end


@interface NewFlashThoughtWindowController ()

@property IBOutlet NSTextField *textField;

@end

@implementation NewFlashThoughtWindowController

- (void)windowDidLoad {
  FLog(@"window did load");
}

- (void)awakeFromNib {
  FLog(@"awakeFromNib");

  if (self.window) {
    [self.window center];
    [self.window setLevel:NSFloatingWindowLevel];
    [self.window makeKeyAndOrderFront:self];
  }
}

- (IBAction)cancelBtnDidClicked:(id)sender {
  FLog(@"cancelButtonDidClick");
  [self close];
}

- (IBAction)okButtonDidClick:(id)sender {
  FLog(@"okButtonDidClicked");;
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
  FLog(@"close");
  [super close];
}

@end
