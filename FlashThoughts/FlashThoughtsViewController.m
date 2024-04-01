//
//  ViewController.m
//  FlashThoughts
//
//  Created by tim on 2024/3/26.
//

#import "FlashThoughtsViewController.h"
#import "FlashThoughtAudioCell.h"
#import "FlashThoughtCell.h"
#import "NewFlashThoughtsViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <LocalAuthentication/LocalAuthentication.h>
#import <UIKit/UIKit.h>

@interface FlashThoughtsViewController ()

@property IBOutlet UIButton *addButton;
@property IBOutlet UIButton *summaryButton;
@property IBOutlet UITableView *tableView;
@property IBOutlet UIView *passwordView;
@property IBOutlet UIActivityIndicatorView *loadingView;

@end

@implementation FlashThoughtsViewController

- (void)userAuth {
  // 创建一个新的LAContext实例
  LAContext *context = [[LAContext alloc] init];

  // 定义一个错误对象
  NSError *error = nil;

  // 检查设备是否支持生物认证
  if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
                           error:&error]) {
    // 设备支持生物认证，请求验证
    [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
            localizedReason:@"请验证以继续"
                      reply:^(BOOL success, NSError *_Nullable error) {
                        // 主线程中处理回调
                        dispatch_async(dispatch_get_main_queue(), ^{
                          if (success) {
                            [self.passwordView setHidden:YES];
                          }
                        });
                      }];
  } else {
    [self.passwordView setHidden:YES];
  }
}

- (void)viewDidLoad {
  [super viewDidLoad];

  [[FlashThoughtManager sharedManager] setDelegate:self];

  self.tableView.delegate = self;
  self.tableView.dataSource = self;
  self.tableView.sectionHeaderHeight = 0.0;
  self.tableView.sectionFooterHeight = 0.0;
  self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

  UILongPressGestureRecognizer *longPressGesture =
      [[UILongPressGestureRecognizer alloc]
          initWithTarget:self
                  action:@selector(handleLongPress:)];
  longPressGesture.minimumPressDuration = 1;
  [self.addButton addGestureRecognizer:longPressGesture];

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

    cell.backgroundColor = [UIColor systemGray5Color];
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
  if (indexPath.section == 1) {
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
    [self.addButton setEnabled:NO];
  } else {
    [self.summaryButton setEnabled:YES];
    [self.loadingView setHidden:YES];
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
          // 使用之前设置的Storyboard ID来初始化ViewController
          NewFlashThoughtsViewController *newFlashVC =
              [storyboard instantiateViewControllerWithIdentifier:
                              @"NewFlashAudioThoughtViewControllerID"];

          // 准备渐显效果
          newFlashVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

          // 呈现视图控制器，使用动画实现渐显效果
          [self presentViewController:newFlashVC animated:YES completion:nil];
        });
      } else {
        // todo;
      }
    }];
  }
}

- (IBAction)addButtonDidClicked:(id)sender {
  UIStoryboard *storyboard =
      [UIStoryboard storyboardWithName:@"NewFlashThoughtsViewController"
                                bundle:nil];
  // 使用之前设置的Storyboard ID来初始化ViewController
  NewFlashThoughtsViewController *newFlashVC =
      [storyboard instantiateViewControllerWithIdentifier:
                      @"NewFlashThoughtsViewControllerID"];

  [self presentViewController:newFlashVC animated:YES completion:nil];
}

- (IBAction)summaryButtonDidClicked:(id)sender {
  [self startLoading:YES];
  BOOL realSent = [[FlashThoughtManager sharedManager] sendAllThoughtsToAI];
  if (!realSent) {
    [self showAlertWithTitle:@"Tips"
                     message:@"You do not have any thought :)"
              confirmHandler:^(UIAlertAction *action){
              }];
    [self startLoading:NO];
  }
}

- (void)thoughtManagerDidAddThought:(FlashThought *)thought {
  [self.tableView reloadData];
}

- (void)allThoughtsDidHandle {
  [self startLoading:NO];
}

- (void)thoughtManagerDidRemoveThought:(FlashThought *)thought {
  // 确保数据源已经更新了，这里不再直接调用[tableView
  // reloadData]，而是使用更平滑的动画效果
  //  [self.tableView reloadData];
}

- (void)thoughtManagerDidUpdateThought:(FlashThought *)thought {
  [self.tableView reloadData];
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
