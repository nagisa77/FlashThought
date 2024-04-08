//
//  AppDelegate.m
//  FlashThoughtsMacOS
//
//  Created by tim on 2024/4/8.
//

#import "AppDelegate.h"
#import <FlashThoughtPlatform/LogManager.h>
#import <FlashThoughtPlatform/LoginService.h>

@interface AppDelegate ()

@property(strong) NSStatusItem *statusItem;
@property(strong) NSPanel *loginPanel;

@end

@implementation AppDelegate

- (void)initConfig {
  [[LogManager sharedManager] setupLogger];
  [[LoginService sharedService] initFIRConfig];
  [[LoginService sharedService] tryRelogin];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  [self initConfig];

  // 获取系统状态栏实例
  NSStatusBar *statusBar = [NSStatusBar systemStatusBar];

  // 创建一个可变长度的状态项
  self.statusItem = [statusBar statusItemWithLength:NSVariableStatusItemLength];
  if (self.statusItem) {
    FLog(@"Status item has been created successfully.");

    // 设置状态项的图标
    self.statusItem.button.image = [NSImage imageNamed:@"Status"];
    if (!self.statusItem.button.image) {
      FLog(@"Failed to load the image. Make sure 'Status' is correct and "
           @"the image is added to the project.");
    }

    // 设置点击状态项时的动作
    self.statusItem.button.action = @selector(statusItemClicked:);

    // 创建菜单
    NSMenu *menu = [[NSMenu alloc] init];
    [menu addItemWithTitle:@"Login"
                    action:@selector(loginClicked:)
             keyEquivalent:@""];
    [menu addItemWithTitle:@"Quit"
                    action:@selector(quitApp:)
             keyEquivalent:@""];

    // 将菜单关联到状态项
    self.statusItem.menu = menu;
  } else {
    FLog(@"Failed to create status item.");
  }
}

// 状态栏图标点击事件处理
- (void)statusItemClicked:(id)sender {
  FLog(@"Status item clicked.");
}

- (void)showLoginPanel {
  if (!self.loginPanel) {
    self.loginPanel =
        [[NSPanel alloc] initWithContentRect:NSMakeRect(0, 0, 0, 0)
                                   styleMask:(NSWindowStyleMaskTitled |
                                              NSWindowStyleMaskClosable)
                                     backing:NSBackingStoreBuffered
                                       defer:NO];
    [self.loginPanel setIsVisible:NO]; 
  }
  self.loginPanel.title = @"Login";
  [self.loginPanel makeKeyAndOrderFront:nil]; // 显示面板

  // 确保面板在显示时应用处于活动状态
  [NSApp activateIgnoringOtherApps:YES];

  // 调用登录函数，传入 loginPanel 作为 window 参数
  dispatch_async(dispatch_get_main_queue(), ^{
    [[LoginService sharedService] loginWithWindow:self.loginPanel];
  });
}

- (void)loginClicked:(id)sender {
  FLog(@"login clicked.");
  [self showLoginPanel];
}

// 菜单项"Quit"的点击事件处理
- (void)quitApp:(id)sender {
  [NSApp terminate:nil];
}

@end
