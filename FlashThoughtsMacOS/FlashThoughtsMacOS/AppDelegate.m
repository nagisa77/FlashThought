//
//  AppDelegate.m
//  FlashThoughtsMacOS
//
//  Created by tim on 2024/4/8.
//

#import "AppDelegate.h"
#import <FlashThoughtPlatform/LogManager.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  [[LogManager sharedManager] setupLogger];
  // 获取系统状态栏实例
  NSStatusBar *statusBar = [NSStatusBar systemStatusBar];

  // 创建一个可变长度的状态项
  NSStatusItem *statusItem =
      [statusBar statusItemWithLength:NSVariableStatusItemLength];
  if (statusItem) {
    FLog(@"Status item has been created successfully.");

    // 设置状态项的图标
    statusItem.button.image = [NSImage imageNamed:@"StatusIcon"];
    if (!statusItem.button.image) {
      FLog(@"Failed to load the image. Make sure 'StatusIcon' is correct and "
           @"the image is added to the project.");
    }

    // 设置点击状态项时的动作
    statusItem.button.action = @selector(statusItemClicked:);

    // 创建菜单
    NSMenu *menu = [[NSMenu alloc] init];
    [menu addItemWithTitle:@"Option 1"
                    action:@selector(option1Clicked:)
             keyEquivalent:@""];
    [menu addItemWithTitle:@"Quit"
                    action:@selector(quitApp:)
             keyEquivalent:@""];

    // 将菜单关联到状态项
    statusItem.menu = menu;
  } else {
    FLog(@"Failed to create status item.");
  }
}

// 状态栏图标点击事件处理
- (void)statusItemClicked:(id)sender {
  FLog(@"Status item clicked.");
}

// 菜单项"Option 1"的点击事件处理
- (void)option1Clicked:(id)sender {
  FLog(@"Option 1 clicked.");
}

// 菜单项"Quit"的点击事件处理
- (void)quitApp:(id)sender {
  [NSApp terminate:nil];
}

@end
