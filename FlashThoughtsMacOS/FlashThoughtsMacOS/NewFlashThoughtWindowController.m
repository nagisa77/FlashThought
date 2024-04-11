//
//  NewFlashThoughtWindowController.m
//  FlashThoughtsMacOS
//
//  Created by 陈嘉挺 on 2024/4/8.
//

#import "NewFlashThoughtWindowController.h"
#import <Cocoa/Cocoa.h>
#import <FlashThoughtPlatform/FlashThoughtManager.h>
#import <FlashThoughtPlatform/LogManager.h>

@interface EditableNSTextField : NSTextField
@end

@implementation EditableNSTextField

- (BOOL)performKeyEquivalent:(NSEvent *)event {
  NSUInteger commandKey = NSEventModifierFlagCommand;
  NSUInteger commandShiftKey =
      NSEventModifierFlagCommand | NSEventModifierFlagShift;

  if (event.type == NSEventTypeKeyDown) {
    NSUInteger modifierFlags =
        [event modifierFlags] & NSEventModifierFlagDeviceIndependentFlagsMask;
    NSString *key = [event charactersIgnoringModifiers];

    if (modifierFlags == commandKey) {
      if ([key isEqualToString:@"x"]) {
        if ([NSApp sendAction:@selector(cut:) to:nil from:self])
          return YES;
      } else if ([key isEqualToString:@"c"]) {
        if ([NSApp sendAction:@selector(copy:) to:nil from:self])
          return YES;
      } else if ([key isEqualToString:@"v"]) {
        if ([NSApp sendAction:@selector(paste:) to:nil from:self])
          return YES;
      } else if ([key isEqualToString:@"z"]) {
        if ([NSApp sendAction:NSSelectorFromString(@"undo:") to:nil from:self])
          return YES;
      } else if ([key isEqualToString:@"a"]) {
        if ([NSApp sendAction:@selector(selectAll:) to:nil from:self])
          return YES;
      }
    } else if (modifierFlags == commandShiftKey) {
      if ([key isEqualToString:@"Z"]) {
        if ([NSApp sendAction:NSSelectorFromString(@"redo:") to:nil from:self])
          return YES;
      }
    }

    // Handling Command+Enter for newline insertion
    if (modifierFlags == commandKey && [key isEqualToString:@"\r"]) {
      [self insertNewline:self];
      return YES;
    }
  }
  return [super performKeyEquivalent:event];
}

@end

@interface NewFlashThoughtWindowController () <NSWindowDelegate>

@property IBOutlet NSTextField *textField;

@end

@implementation NewFlashThoughtWindowController

- (void)windowDidLoad {
  FLog(@"window did load");

  self.window.delegate = self;

  [self.window setLevel:NSFloatingWindowLevel];
  [self.window setOpaque:NO];
  [self.window setBackgroundColor:[NSColor clearColor]];
  [self.window setStyleMask:self.window.styleMask & ~NSWindowStyleMaskClosable &
                            ~NSWindowStyleMaskMiniaturizable &
                            ~NSWindowStyleMaskResizable];

  NSRect screenFrame = [[NSScreen mainScreen] frame];
  NSRect windowFrame = [self.window frame];
  CGFloat newY = screenFrame.size.height - windowFrame.size.height;
  CGFloat newX = (screenFrame.size.width - windowFrame.size.width) / 2;
  NSRect startFrame = NSMakeRect(newX, newY - 300, windowFrame.size.width,
                                 windowFrame.size.height);
  NSRect finalFrame = NSMakeRect(newX, newY - 60, windowFrame.size.width,
                                 windowFrame.size.height);

  [self.window setFrame:startFrame display:YES];
  self.window.alphaValue = .0;

  // 执行滑入动画
  [NSAnimationContext
      runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = .3; // 动画时长
        [[self.window animator] setFrame:finalFrame display:YES];
        [self.window animator].alphaValue = 1.0;
      }
      completionHandler:^{
        FLog(@"Animation completed");
        NSRect frame = self.window.frame;
        frame.size.width += 1;
        [self.window setFrame:frame display:YES animate:NO];
        frame.size.width -= 1;
        [self.window setFrame:frame display:YES animate:NO];
      }];
}

- (void)awakeFromNib {
  FLog(@"awakeFromNib");

  self.textField.placeholderString =
      @"Please input your thought :) \n\ne.g.\n'I want to learn swift language "
      @"tonight!'\n'Why is the earth round? It’s amazing😳!!'";

  if (self.window) {
    NSVisualEffectView *visualEffectView =
        (NSVisualEffectView *)self.window.contentView;
    visualEffectView.material = NSVisualEffectMaterialFullScreenUI;
    visualEffectView.blendingMode = NSVisualEffectBlendingModeBehindWindow;
    visualEffectView.state = NSVisualEffectStateActive;

    [NSApp activateIgnoringOtherApps:YES];
  }
}

- (IBAction)cancelBtnDidClicked:(id)sender {
  FLog(@"cancelButtonDidClick");
  [self runAnamiteAndClose];
}

- (IBAction)okButtonDidClick:(id)sender {
  FLog(@"okButtonDidClicked");
  ;
  if (![self.textField.stringValue isEqual:@""]) {
    FlashThought *fs =
        [[FlashThought alloc] initWithType:FlashThoughtTypeTextFlashThought
                                      date:[NSDate date]];
    fs.content = self.textField.stringValue;
    FLog(@"add a flash thought %@", fs.content);
    [[FlashThoughtManager sharedManager] addThought:fs];
  }
  [self runAnamiteAndClose];
}

- (void)close {
  FLog(@"close");
  [self runAnamiteAndClose];
}

- (void)runAnamiteAndClose {
  NSRect windowFrame = [self.window frame];
  NSRect finalFrame =
      NSMakeRect(windowFrame.origin.x, windowFrame.origin.y - 60,
                 windowFrame.size.width, windowFrame.size.height);

  // 执行滑出动画
  [NSAnimationContext
      runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = .3; // 动画时长
        [[self.window animator] setFrame:finalFrame display:YES];
        [self.window animator].alphaValue = 0.0;
      }
      completionHandler:^{
        FLog(@"Animation completed");
        [self.window close];
      }];
}

- (BOOL)windowShouldClose:(NSWindow *)sender {
  [self runAnamiteAndClose];
  // 返回 NO，因为我们要在动画完成后手动关闭窗口
  return NO;
}

@end
