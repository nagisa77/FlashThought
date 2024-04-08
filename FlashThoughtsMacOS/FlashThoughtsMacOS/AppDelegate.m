//
//  AppDelegate.m
//  FlashThoughtsMacOS
//
//  Created by tim on 2024/4/8.
//

#import "AppDelegate.h"
#import <FlashThoughtPlatform/LogManager.h>
#import <FlashThoughtPlatform/FlashThoughtManager.h>
#import <FlashThoughtPlatform/LoginService.h>
#import "NewFlashThoughtWindowController.h"

@interface AppDelegate () <LoginServiceDelegate>

@property(strong) NSStatusItem *statusItem;
@property(strong) NSPanel *loginPanel;
@property(strong) NewFlashThoughtWindowController *flashThoughtWindowController;

@end

@implementation AppDelegate

- (void)initConfig {
  [[LogManager sharedManager] setupLogger];
  [[LoginService sharedService] addDelegate:self];
  [[LoginService sharedService] initFIRConfig];
  [[LoginService sharedService] tryRelogin];
  [FlashThoughtManager sharedManager];
}

- (void)updateMenu {
  NSMenu *menu = nil;
  if (self.statusItem.menu) {
    menu = self.statusItem.menu;
    [menu removeAllItems];
  } else {
    NSMenu *menu = [[NSMenu alloc] init];
    self.statusItem.menu = menu;
  }
  if ([[LoginService sharedService] isLoggedIn]) {
    [menu addItemWithTitle:[NSString stringWithFormat:@"id: %@", [[LoginService sharedService] username]]
                    action:nil
             keyEquivalent:@""];
    [menu addItemWithTitle:@"New Flash Though"
                    action:@selector(newFlashThoughtClicked:)
             keyEquivalent:@"n"];
    
    [menu addItemWithTitle:@"Sign Out"
                    action:@selector(signOutClicked:)
             keyEquivalent:@"s"];
  } else {
    [menu addItemWithTitle:@"Login"
                    action:@selector(loginClicked:)
             keyEquivalent:@"l"];
  }
  
  [menu addItemWithTitle:@"Debug With Log"
                  action:@selector(debugWithLog:)
           keyEquivalent:@"d"];

  [menu addItemWithTitle:@"Quit"
                  action:@selector(quitApp:)
           keyEquivalent:@"q"];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  [self initConfig];

  NSStatusBar *statusBar = [NSStatusBar systemStatusBar];

  self.statusItem = [statusBar statusItemWithLength:NSVariableStatusItemLength];
  if (self.statusItem) {
    FLog(@"Status item has been created successfully.");

    self.statusItem.button.image = [NSImage imageNamed:@"Status"];
    if (!self.statusItem.button.image) {
      FLog(@"Failed to load the image. Make sure 'Status' is correct and "
           @"the image is added to the project.");
    }

    self.statusItem.button.action = @selector(statusItemClicked:);
    [self updateMenu];
  } else {
    FLog(@"Failed to create status item.");
  }
}

// 状态栏图标点击事件处理
- (void)statusItemClicked:(id)sender {
  FLog(@"Status item clicked.");
}

- (void)newFlashThoughtClicked {
  if (self.flashThoughtWindowController) {
    [self.flashThoughtWindowController close];
  }
  self.flashThoughtWindowController = [[NewFlashThoughtWindowController alloc] initWithWindowNibName:@"NewFlashThoughtWindowController"];
  [self.flashThoughtWindowController showWindow:self];
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

- (void)signOutClicked:(id)sender {
  FLog(@"sign out clicked.");
  [[LoginService sharedService] logout];
}

- (void)loginClicked:(id)sender {
  FLog(@"login clicked.");
  [self showLoginPanel];
}

- (void)newFlashThoughtClicked:(id)sender {
  FLog(@"new flash thought clicked.");
  [self newFlashThoughtClicked];
}

- (void)quitApp:(id)sender {
  [NSApp terminate:nil];
}

- (void)openLogFolder {
  NSURL *fileURL = [NSURL fileURLWithPath:[[LogManager sharedManager] getLogFilePath]];
  NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
  [workspace activateFileViewerSelectingURLs:@[fileURL]];
}

- (void)debugWithLog:(id)sender {
  [self openLogFolder];
}

- (void)onSignInSuccess {
  [self updateMenu];
}

- (void)onSignInFailed {
  [self updateMenu];
}

- (void)onSignOutSuccess {
  [self updateMenu];
}

@end
