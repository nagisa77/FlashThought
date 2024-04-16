//
//  AppDelegate.m
//  FlashThoughtsMacOS
//
//  Created by tim on 2024/4/8.
//

#import "AppDelegate.h"
#import "NewFlashThoughtWindowController.h"
#import <FlashThoughtPlatform/FlashThoughtManager.h>
#import <FlashThoughtPlatform/LogManager.h>
#import <FlashThoughtPlatform/LoginService.h>

@interface AppDelegate () <LoginServiceDelegate>

@property(strong) NSStatusItem *statusItem;
@property(strong) NSMenu *menu;
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
  if (!self.menu) {
    self.menu = [[NSMenu alloc] init];
  }
  [self.menu removeAllItems];
  if ([[LoginService sharedService] isLoggedIn]) {
    [self.menu addItemWithTitle:[NSString
                               stringWithFormat:@"id: %@",
                                                [[LoginService sharedService]
                                                    username]]
                    action:nil
             keyEquivalent:@""];
    [self.menu addItemWithTitle:@"New Flash Though"
                    action:@selector(newFlashThoughtClicked:)
             keyEquivalent:@"n"];

    [self.menu addItemWithTitle:@"Sign Out"
                    action:@selector(signOutClicked:)
             keyEquivalent:@"s"];
  } else {
    [self.menu addItemWithTitle:@"Login"
                    action:@selector(loginClicked:)
             keyEquivalent:@"l"];
  }

  [self.menu addItemWithTitle:@"Debug With Log"
                  action:@selector(debugWithLog:)
           keyEquivalent:@"d"];

  [self.menu addItemWithTitle:@"Quit" action:@selector(quitApp:) keyEquivalent:@"q"];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  [self initConfig];

  NSStatusBar *statusBar = [NSStatusBar systemStatusBar];

  self.statusItem = [statusBar statusItemWithLength:NSSquareStatusItemLength];
  if (self.statusItem) {
    FLog(@"Status item has been created successfully.");

    self.statusItem.button.image = [NSImage imageNamed:@"Status"];
    if (!self.statusItem.button.image) {
      FLog(@"Failed to load the image. Make sure 'Status' is correct and "
           @"the image is added to the project.");
    }
//    
    self.statusItem.button.target = self;
    self.statusItem.button.action = @selector(statusItemClicked:);
    FLog(@"statusItem is Visible: %d", self.statusItem.isVisible);
    [self updateMenu];
  } else {
    FLog(@"Failed to create status item.");
  }
}

// 状态栏图标点击事件处理
- (void)statusItemClicked:(id)sender {
  FLog(@"Status item clicked.");

  if (!self.menu) {
    [self updateMenu];
  }

  NSRect buttonRect = self.statusItem.button.frame;
  NSPoint menuOrigin = NSMakePoint(NSMidX(buttonRect) - self.menu.size.width / 2, 0);

  [self.menu popUpMenuPositioningItem:nil
                           atLocation:menuOrigin
                               inView:self.statusItem.button];
}


- (void)newFlashThoughtClicked {
  if (self.flashThoughtWindowController) {
    [self.flashThoughtWindowController close];
  }
  self.flashThoughtWindowController = [[NewFlashThoughtWindowController alloc]
      initWithWindowNibName:@"NewFlashThoughtWindowController"];
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
  NSURL *fileURL =
      [NSURL fileURLWithPath:[[LogManager sharedManager] getLogFilePath]];
  NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
  [workspace activateFileViewerSelectingURLs:@[ fileURL ]];
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
