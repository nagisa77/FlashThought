//
//  ViewController.m
//  FlashThoughts
//
//  Created by tim on 2024/3/26.
//

#import "FlashThoughtsViewController.h"
#import "FlashThoughtAudioCell.h"
#import "FlashThoughtCell.h"
#import "MBProgressHUD.h"
#import "NewFlashThoughtsViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <LocalAuthentication/LocalAuthentication.h>
#import <UIKit/UIKit.h>
#import <FlashThoughtPlatform/LogManager.h>

@interface FlashThoughtsViewController ()

@property IBOutlet UIButton *addButton;
@property IBOutlet UIButton *summaryButton;
@property IBOutlet UIButton *avaterButton;
@property IBOutlet UILabel *topLeftLabel;
@property IBOutlet UITableView *tableView;
@property IBOutlet UIView *passwordView;
@property IBOutlet UIActivityIndicatorView *loadingView;
@property(strong, nonatomic) MBProgressHUD *loadingHud;

@end

@implementation FlashThoughtsViewController

- (void)userAuth {
  // 创建一个新的LAContext实例
  LAContext *context = [[LAContext alloc] init];
  
  // 定义一个错误对象
  NSError *error = nil;
  
  // 检查设备是否支持设备所有者身份验证（包括生物识别和密码）
  if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthentication
                           error:&error]) {
    // 请求身份验证
    [context evaluatePolicy:LAPolicyDeviceOwnerAuthentication
            localizedReason:@"请验证以继续"
                      reply:^(BOOL success, NSError *error) {
      dispatch_async(dispatch_get_main_queue(), ^{
        if (success) {
          [self.passwordView setHidden:YES];
        } else {
          // 认证失败，可以选择处理错误或者什么都不做
        }
      });
    }];
  } else {
    [self.passwordView setHidden:YES];
  }
}

- (void)showMessageWithTitle:(NSString *)title
                     content:(NSString *)content
                  completion:(void (^)(void))completionBlock {
  UIImpactFeedbackGenerator *mediumGenerator =
  [[UIImpactFeedbackGenerator alloc]
   initWithStyle:UIImpactFeedbackStyleMedium];
  [mediumGenerator prepare];
  [mediumGenerator impactOccurred];
  
  MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
  
  // Set the text mode to show only text.
  hud.mode = MBProgressHUDModeText;
  hud.label.text = NSLocalizedString(content, title);
  // Move to bottm center.
  hud.offset = CGPointMake(0.f, 250.f);
  hud.animationType = MBProgressHUDAnimationZoom;
  [hud setCompletionBlock:completionBlock];
  
  [hud hideAnimated:YES afterDelay:3.f];
}

- (UIImage *)resizeAndRoundImage:(UIImage *)image toSize:(CGSize)newSize {
  // 开始一个图形上下文
  UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
  // 创建圆形裁剪区域
  CGRect rect = CGRectMake(0, 0, newSize.width, newSize.height);
  [[UIBezierPath bezierPathWithOvalInRect:rect] addClip];
  // 绘制图像
  [image drawInRect:rect];
  // 从上下文中获取修改后的图像
  UIImage *roundedImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  return roundedImage;
}

- (void)loadAvatarFromURL:(NSURL *)url {
  CGSize boundSize = self.avaterButton.bounds.size;
  boundSize.width -= 4;
  boundSize.height -= 4;
  NSURLSessionTask *task = [[NSURLSession sharedSession]
                            dataTaskWithURL:url
                            completionHandler:^(NSData *_Nullable data,
                                                NSURLResponse *_Nullable response,
                                                NSError *_Nullable error) {
    if (data) {
      UIImage *image = [UIImage imageWithData:data];
      UIImage *resizedImage = [self resizeAndRoundImage:image
                                                 toSize:boundSize];
      if (resizedImage) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [self.avaterButton setImage:resizedImage
                             forState:UIControlStateNormal];
        });
      }
    }
  }];
  [task resume];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [[FlashThoughtManager sharedManager] setDelegate:self];
  [[LoginService sharedService] addDelegate:self];
  
  self.tableView.delegate = self;
  self.tableView.dataSource = self;
  self.tableView.sectionHeaderHeight = 0.0;
  self.tableView.sectionFooterHeight = 0.0;
  self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  
  [self checkAvatar];
  
  self.topLeftLabel.alpha = 0.0;
  
  UILongPressGestureRecognizer *longPressGesture =
  [[UILongPressGestureRecognizer alloc]
   initWithTarget:self
   action:@selector(handleLongPress:)];
  longPressGesture.minimumPressDuration = 1;
  [self.addButton addGestureRecognizer:longPressGesture];
  
  if (@available(iOS 13.0, *)) {
    {
      UIContextMenuInteraction *contextMenuInteraction =
      [[UIContextMenuInteraction alloc] initWithDelegate:self];
      [self.summaryButton addInteraction:contextMenuInteraction];
    }
    // 头像先不支持长按
    //    {
    //      UIContextMenuInteraction *contextMenuInteraction =
    //          [[UIContextMenuInteraction alloc] initWithDelegate:self];
    //      [self.avaterButton addInteraction:contextMenuInteraction];
    //    }
  }
  
  [self userAuth];
  [self.loadingView setHidden:YES];
  
  // 注册XIB
  {
    UINib *cellNib = [UINib nibWithNibName:@"FlashThoughtCell" bundle:nil];
    [self.tableView registerNib:cellNib
         forCellReuseIdentifier:@"FlashThoughtCell"];
  }
  {
    UINib *cellNib = [UINib nibWithNibName:@"FlashThoughtAudioCell" bundle:nil];
    [self.tableView registerNib:cellNib
         forCellReuseIdentifier:@"FlashThoughtAudioCell"];
  }
  
  [[NSNotificationCenter defaultCenter]
   addObserver:self
   selector:@selector(appWillEnterForeground:)
   name:UIApplicationWillEnterForegroundNotification
   object:nil];
  
  [[NSNotificationCenter defaultCenter]
   addObserver:self
   selector:@selector(appDidEnterBackground:)
   name:UIApplicationDidEnterBackgroundNotification
   object:nil];
}

- (void)checkAvatar {
  if ([[LoginService sharedService] isLoggedIn]) {
    self.avaterButton.alpha = 0.0;
    [self.avaterButton setHidden:NO];
    [UIView animateWithDuration:0.5
                     animations:^{
      self.avaterButton.alpha = 1.0;
    }];
    [self loadAvatarFromURL:[[LoginService sharedService] userAvatarURL]];
  } else {
    [self.avaterButton setHidden:YES];
  }
}

- (void)appWillEnterForeground:(NSNotification *)notification {
  [[FlashThoughtManager sharedManager] loadStoredThoughts];
  [self.tableView reloadData];
  [self userAuth];
}

- (void)appDidEnterBackground:(NSNotification *)notification {
  [self.passwordView setHidden:NO];
}

- (void)dealloc {
  [[FlashThoughtManager sharedManager] setDelegate:nil];
  [[LoginService sharedService] removeDelegate:self];
  self.tableView.delegate = nil;
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updateLeftTopTitle:(UIScrollView *)scrollView {
  if (scrollView.contentOffset.y <= 60) {
    self.topLeftLabel.alpha = 0.0;
  } else if (scrollView.contentOffset.y > 60 &&
             scrollView.contentOffset.y <= 100) {
    self.topLeftLabel.alpha = (scrollView.contentOffset.y - 60) / 40;
  } else if (scrollView.contentOffset.y > 100) {
    self.topLeftLabel.alpha = 1.0;
  }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  [self updateLeftTopTitle:scrollView];
}

// todo: 重构这里
- (void)showAPIKeySettings {
  UIImpactFeedbackGenerator *lightGenerator = [[UIImpactFeedbackGenerator alloc]
                                               initWithStyle:UIImpactFeedbackStyleLight];
  [lightGenerator impactOccurred];
  UIAlertController *alertController =
  [UIAlertController alertControllerWithTitle:@"OpenAI API key"
                                      message:@"Need the key to "
   @"summary your "
   @"flash thoughts"
                               preferredStyle:UIAlertControllerStyleAlert];
  
  [alertController
   addTextFieldWithConfigurationHandler:^(UITextField *textField) {
    textField.placeholder = @"api key...";
    NSString *apiKey = [[GPTVisitor sharedInstance] getAPIKey];
    if (apiKey != nil) {
      [textField setText:apiKey];
    }
  }];
  
  UIAlertAction *confirmAction = [UIAlertAction
                                  actionWithTitle:@"Confirm"
                                  style:UIAlertActionStyleDefault
                                  handler:^(UIAlertAction *action) {
    // 获取输入框的内容
    UITextField *textField = alertController.textFields[0];
    if (![textField.text isEqual:@""]) {
      [lightGenerator impactOccurred];
      [[GPTVisitor sharedInstance] updateAPIKey:textField.text];
    }
  }];
  
  UIAlertAction *cancelAction =
  [UIAlertAction actionWithTitle:@"Cancel"
                           style:UIAlertActionStyleCancel
                         handler:nil];
  
  [alertController addAction:confirmAction];
  [alertController addAction:cancelAction];
  
  [self presentViewController:alertController animated:YES completion:nil];
}

- (void)signout {
  [[LoginService sharedService] logout];
}

- (void)signInWithGoogle {
  [[LoginService sharedService] loginWithViewController:self];
}

- (void)onSignInSuccess {
  [self showMessageWithTitle:@"signin successed"
                     content:@"Sign In Success :)"
                  completion:nil];
  [self checkAvatar];
}

- (void)onSignInFailed {
  [self showMessageWithTitle:@"signin failed"
                     content:@"Sign In Failed :("
                  completion:nil];
  [self checkAvatar];
}

- (void)onSignOutSuccess {
  [self showMessageWithTitle:@"signout success"
                     content:@"Sign Out Success :)"
                  completion:nil];
  [self checkAvatar];
}

- (void)shareLog {
  NSString *filePath = [[LogManager sharedManager] getLogFilePath];

  NSURL *fileURL = [NSURL fileURLWithPath:filePath];
  if (fileURL) {
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[fileURL] applicationActivities:nil];

    [self presentViewController:activityVC animated:YES completion:nil];
  } else {
    FLog(@"fileURL null");
  }
}

- (void)showProxyHostSetting {
  UIImpactFeedbackGenerator *lightGenerator = [[UIImpactFeedbackGenerator alloc]
      initWithStyle:UIImpactFeedbackStyleLight];
  [lightGenerator impactOccurred];
  // 创建UIAlertController
  UIAlertController *alertController =
      [UIAlertController alertControllerWithTitle:@"Proxy Host"
                                          message:@"proxy to visit openai"
                                   preferredStyle:UIAlertControllerStyleAlert];

  [alertController
      addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"host...";
        NSString *host = [[GPTVisitor sharedInstance] getProxyHost];
        if (host != nil) {
          [textField setText:host];
        }
      }];

  UIAlertAction *confirmAction = [UIAlertAction
      actionWithTitle:@"Confirm"
                style:UIAlertActionStyleDefault
              handler:^(UIAlertAction *action) {
                UITextField *textField = alertController.textFields[0];
                if (![textField.text isEqual:@""]) {
                  [lightGenerator impactOccurred];
                  [[GPTVisitor sharedInstance] updateProxyHost:textField.text];
                }
              }];

  UIAlertAction *cancelAction =
      [UIAlertAction actionWithTitle:@"Cancel"
                               style:UIAlertActionStyleCancel
                             handler:nil];

  [alertController addAction:confirmAction];
  [alertController addAction:cancelAction];

  [self presentViewController:alertController animated:YES completion:nil];
}

- (UIMenu *)summaryButtonActionsMenu {
  UIAction *action1 = [UIAction actionWithTitle:@"API Key Setting"
                                          image:nil
                                     identifier:nil
                                        handler:^(UIAction *_Nonnull action) {
                                          FLog(@"showAPIKeySettings click");
                                          [self showAPIKeySettings];
                                        }];
  UIAction *action2 = [UIAction actionWithTitle:@"Proxy Host Setting"
                                          image:nil
                                     identifier:nil
                                        handler:^(UIAction *_Nonnull action) {
                                          FLog(@"showProxyHostSetting click");
                                          [self showProxyHostSetting];
                                        }];

  UIAction *action3 = nil;
  if ([[LoginService sharedService] isLoggedIn]) {
    action3 = [UIAction actionWithTitle:@"SignOut"
                                  image:nil
                             identifier:nil
                                handler:^(UIAction *_Nonnull action) {
                                  dispatch_async(dispatch_get_main_queue(), ^{
                                    FLog(@"signout click");
                                    [self signout];
                                  });
                                }];
  } else {
    action3 = [UIAction actionWithTitle:@"Sync Between Cloud"
                                  image:nil
                             identifier:nil
                                handler:^(UIAction *_Nonnull action) {
                                  dispatch_async(dispatch_get_main_queue(), ^{
                                    FLog(@"signInWithGoogle click");
                                    [self signInWithGoogle];
                                  });
                                }];
  }
  
  UIAction *action4 = [UIAction actionWithTitle:@"Debug Log"
                                          image:nil
                                     identifier:nil
                                        handler:^(UIAction *_Nonnull action) {
                                          FLog(@"shareLog click");
                                          [self shareLog];
                                        }];

  return [UIMenu menuWithTitle:@"Settings"
                      children:@[ action1, action2, action3, action4 ]];
}

// UIContextMenuInteractionDelegate 方法
- (nullable UIContextMenuConfiguration *)
            contextMenuInteraction:(UIContextMenuInteraction *)interaction
    configurationForMenuAtLocation:(CGPoint)location API_AVAILABLE(ios(13.0)) {
  if ([self.summaryButton.interactions containsObject:interaction]) {
    UIContextMenuConfiguration *configuration = [UIContextMenuConfiguration
        configurationWithIdentifier:nil
                    previewProvider:nil
                     actionProvider:^UIMenu *_Nullable(
                         NSArray<UIMenuElement *> *_Nonnull suggestedActions) {
                       return [self summaryButtonActionsMenu];
                     }];
    return configuration;
  } else {
    return nil;
  }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 2;
}

- (CGFloat)tableView:(UITableView *)tableView
    heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  // 让UITableView根据Auto Layout约束自动计算高度
  return UITableViewAutomaticDimension;
}

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
  if (section == 0) {
    return 1;
  } else {
    return [[FlashThoughtManager sharedManager] allThoughts].count;
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.section == 0) {
    UITableViewCell *cell =
        [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];

    if (!cell) {
      cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                    reuseIdentifier:@"UITableViewCell"];
    }

    cell.textLabel.text = @"闪念笔记";
    cell.textLabel.font = [UIFont systemFontOfSize:30 weight:UIFontWeightBold];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
  } else {
    NSArray<FlashThought *> *allThoughts =
        [[FlashThoughtManager sharedManager] allThoughts];
    FlashThought *thought = allThoughts[indexPath.row];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *nowDate =
        [dateFormatter stringFromDate:allThoughts[indexPath.row].date];
    if (thought.type == FlashThoughtTypeTextFlashThought) {
      FlashThoughtCell *cell =
          [tableView dequeueReusableCellWithIdentifier:@"FlashThoughtCell"
                                          forIndexPath:indexPath];

      if (!cell) {
        cell =
            [[FlashThoughtCell alloc] initWithStyle:UITableViewCellStyleDefault
                                    reuseIdentifier:@"FlashThoughtCell"];
      }
      cell.contentLabel.text = allThoughts[indexPath.row].content;
      cell.dateLabel.text = nowDate;
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
      return cell;
    } else if (thought.type == FlashThoughtTypeAudioFlashThought ||
               thought.type == FlashThoughtTypeAudioToTextFlashThought) {
      FlashThoughtAudioCell *cell =
          [tableView dequeueReusableCellWithIdentifier:@"FlashThoughtAudioCell"
                                          forIndexPath:indexPath];

      if (!cell) {
        cell = [[FlashThoughtAudioCell alloc]
              initWithStyle:UITableViewCellStyleDefault
            reuseIdentifier:@"FlashThoughtAudioCell"];
      }

      cell.dateLabel.text = nowDate;
      [cell setupAudioPlayerWithURL:
                [FlashThoughtManager
                    audioRecordingURLFromFileName:thought.audioFileName]];
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
      return cell;
    } else {
      return nil;
    }
  }
}

- (BOOL)tableView:(UITableView *)tableView
    canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.section == 0) {
    return NO;
  }
  return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.section == 1 &&
      ![[FlashThoughtManager sharedManager] isHandlingAllThoughts]) {
    return UITableViewCellEditingStyleDelete;
  }
  return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView
    commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
     forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    FlashThoughtManager *manager = [FlashThoughtManager sharedManager];
    NSArray<FlashThought *> *allThoughts = [manager allThoughts];
    FlashThought *thoughtToDelete = allThoughts[indexPath.row];
    [manager removeThought:thoughtToDelete];

    [tableView deleteRowsAtIndexPaths:@[ indexPath ]
                     withRowAnimation:UITableViewRowAnimationFade];

    [self updateLeftTopTitle:self.tableView];
  }
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView
    heightForHeaderInSection:(NSInteger)section {
  if (section == 0) {
    return 70;
  } else {
    return tableView.sectionHeaderHeight;
  }
}

- (CGFloat)tableView:(UITableView *)tableView
    heightForFooterInSection:(NSInteger)section {
  return tableView.sectionFooterHeight;
}

- (void)startLoading:(BOOL)load {
  if (load) {
    [self.summaryButton setEnabled:NO];
    [self.loadingView setHidden:NO];
    [self.loadingView startAnimating];

    self.loadingHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.loadingHud.backgroundView.style =
        MBProgressHUDBackgroundStyleSolidColor;
    self.loadingHud.backgroundView.color = [UIColor colorWithWhite:0.f
                                                             alpha:0.1f];

    [self.addButton setEnabled:NO];
  } else {
    [self.summaryButton setEnabled:YES];
    [self.loadingView setHidden:YES];
    [self.loadingHud hideAnimated:YES];
    [self.loadingView stopAnimating];
    [self.addButton setEnabled:YES];
  }
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer {
  if (![self.addButton isEnabled]) {
    return;
  }

  if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
    [AVAudioSession.sharedInstance requestRecordPermission:^(BOOL granted) {
      if (granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
          UIStoryboard *storyboard = [UIStoryboard
              storyboardWithName:@"NewFlashAudioThoughtViewController"
                          bundle:nil];

          NewFlashThoughtsViewController *newFlashVC =
              [storyboard instantiateViewControllerWithIdentifier:
                              @"NewFlashAudioThoughtViewControllerID"];

          newFlashVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

          [self presentViewController:newFlashVC animated:YES completion:nil];
        });
      } else {
        // todo;
      }
    }];
  }
}

- (IBAction)addButtonDidClicked:(id)sender {
  UIImpactFeedbackGenerator *mediumGenerator =
      [[UIImpactFeedbackGenerator alloc]
          initWithStyle:UIImpactFeedbackStyleMedium];
  [mediumGenerator prepare];
  [mediumGenerator impactOccurred];

  UIStoryboard *storyboard =
      [UIStoryboard storyboardWithName:@"NewFlashThoughtsViewController"
                                bundle:nil];
  NewFlashThoughtsViewController *newFlashVC =
      [storyboard instantiateViewControllerWithIdentifier:
                      @"NewFlashThoughtsViewControllerID"];

  [self presentViewController:newFlashVC animated:YES completion:nil];
}

- (IBAction)summaryButtonDidClicked:(id)sender {
  if ([[GPTVisitor sharedInstance] getAPIKey] == nil) {
    [self showAPIKeySettings];
    return;
  }

  [self startLoading:YES];
  BOOL realSent = [[FlashThoughtManager sharedManager] sendAllThoughtsToAI];
  if (!realSent) {
    [self showMessageWithTitle:@"Tips"
                       content:@"You do not have any thought :)"
                    completion:nil];
    [self startLoading:NO];
  }
}

- (void)thoughtManagerDidAddThought:(FlashThought *)thought {
  [self.tableView reloadData];
}

- (void)shouldReloadData {
  [self.tableView reloadData];
}

- (void)allThoughtsDidHandle {
  [self startLoading:NO];
  [self showMessageWithTitle:@"save complete"
                     content:@"Saved to Reminders :)"
                  completion:nil];
}

- (void)thoughtManagerDidRemoveThought:(FlashThought *)thought {
  // 确保数据源已经更新了，这里不再直接调用[tableView
  // reloadData]，而是使用更平滑的动画效果
  //  [self.tableView reloadData];
}

- (void)thoughtManagerDidUpdateThought:(FlashThought *)thought {
  [self.tableView reloadData];
}

- (void)shouldStopHandlingThoughtsByError:(NSError *)error {
  if (error.code == NSURLErrorUnsupportedURL) {
    [self startLoading:NO];
    [[FlashThoughtManager sharedManager] cancelSendAllThoughtsToAI];
    [self showMessageWithTitle:@"unspport url"
                       content:@"Unspport proxy URL :("
                    completion:^{
                      [self showProxyHostSetting];
                    }];
  }
}

- (void)thoughtsDidSaveToReminders:(NSArray<FlashThought *> *)thoughts {
  for (FlashThought *thought in thoughts) {
    NSInteger row = [[FlashThoughtManager sharedManager] removeThought:thought];
    if (row != NSNotFound) { // 确保找到了思考并被删除
      NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:1];
      [self.tableView deleteRowsAtIndexPaths:@[ indexPath ]
                            withRowAnimation:UITableViewRowAnimationFade];
    }
  }
}

- (void)thoughtsDidSentToAI:(NSArray<FlashThought *> *)thoughts {
}

- (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
            confirmHandler:(void (^)(UIAlertAction *action))confirmHandler {
  UIAlertController *alertController =
      [UIAlertController alertControllerWithTitle:title
                                          message:message
                                   preferredStyle:UIAlertControllerStyleAlert];

  UIAlertAction *confirmAction =
      [UIAlertAction actionWithTitle:@"OK"
                               style:UIAlertActionStyleDefault
                             handler:confirmHandler];

  [alertController addAction:confirmAction];

  [self presentViewController:alertController animated:YES completion:nil];
}

@end
