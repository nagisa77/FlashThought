//
//  ViewController.m
//  FlashThoughts
//
//  Created by tim on 2024/3/26.
//

#import "FlashThoughtsViewController.h"
#import "FlashThoughtCell.h"
#import "NewFlashThoughtsViewController.h"
#import <LocalAuthentication/LocalAuthentication.h>
#import <UIKit/UIKit.h>

@interface FlashThoughtsViewController ()

@property IBOutlet UIButton *addButton;
@property IBOutlet UIButton *summaryButton;
@property IBOutlet UITableView *tableView;
@property IBOutlet UIView *passwordView;
@property IBOutlet UIActivityIndicatorView *loadingView;

@property(strong, nonatomic) CAShapeLayer *checkmarkLayer;

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

  [self userAuth];

  // 初始化打勾的CAShapeLayer
  self.checkmarkLayer = [CAShapeLayer layer];
  self.checkmarkLayer.strokeColor = [UIColor greenColor].CGColor;
  self.checkmarkLayer.lineWidth = 5;
  self.checkmarkLayer.fillColor = [UIColor clearColor].CGColor;
  [self.summaryButton.layer addSublayer:self.checkmarkLayer];

  [self.loadingView setHidden:YES];

  // 注册XIB
  UINib *cellNib = [UINib nibWithNibName:@"FlashThoughtCell" bundle:nil];
  [self.tableView registerNib:cellNib
       forCellReuseIdentifier:@"FlashThoughtCell"];
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
    FlashThoughtCell *cell =
        [tableView dequeueReusableCellWithIdentifier:@"FlashThoughtCell"
                                        forIndexPath:indexPath];

    if (!cell) {
      cell = [[FlashThoughtCell alloc] initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:@"FlashThoughtCell"];
    }

    //    FlashThoughtCell *cell = [[FlashThoughtCell alloc] init];

    NSArray<FlashThought *> *allThoughts =
        [[FlashThoughtManager sharedManager] allThoughts];
    cell.contentLabel.text = allThoughts[indexPath.row].content;

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    cell.dateLabel.text =
        [dateFormatter stringFromDate:allThoughts[indexPath.row].date];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
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
  } else {
    [self.summaryButton setEnabled:YES];
    [self.loadingView setHidden:YES];
    [self.loadingView stopAnimating];
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
  [[FlashThoughtManager sharedManager] sendAllThoughtsToAI];
  dispatch_queue_t mainQueue = dispatch_get_main_queue();
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)),
                 mainQueue, ^{
                   [self startLoading:NO];
                 });
}

- (void)thoughtManagerDidAddThought:(FlashThought *)thought {
  [self.tableView reloadData];
}

- (void)thoughtManagerDidRemoveThought:(FlashThought *)thought {
  // 确保数据源已经更新了，这里不再直接调用[tableView
  // reloadData]，而是使用更平滑的动画效果
  //  [self.tableView reloadData];
}

- (void)thoughtManagerDidUpdateThought:(FlashThought *)thought {
  [self.tableView reloadData];
}

@end
