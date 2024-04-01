//
//  NewFlashAudioThoughtViewController.m
//  FlashThoughts
//
//  Created by tim on 2024/3/28.
//

#import "NewFlashAudioThoughtViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#import "FlashThoughtManager.h"

@interface NewFlashAudioThoughtViewController () <AVAudioRecorderDelegate>
@property IBOutlet UILabel *recordingLabel;
@property IBOutlet UILabel *timeLabel;
@property(strong, nonatomic) NSTimer *timer;
@property(strong, nonatomic) NSDate *audioDate;
@property(strong, nonatomic) NSString *fileName;
@property(assign, nonatomic) NSInteger secondsElapsed;
@property(assign, nonatomic) NSInteger recordingTextIndex;
@property(assign, nonatomic) BOOL save;
@property (strong, nonatomic) AVAudioRecorder *audioRecorder;
@end

@implementation NewFlashAudioThoughtViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.secondsElapsed = 0;
  self.recordingTextIndex = 0;
  self.save = NO;
  self.audioDate = [NSDate date];
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
  self.fileName = [NSString stringWithFormat: @"FlashThought-%@.m4a",
                   [dateFormatter stringFromDate:self.audioDate]];
  
  [self setupAudioRecorder];
  self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                target:self
                                              selector:@selector(updateLabels)
                                              userInfo:nil
                                               repeats:YES];
  
  [self.audioRecorder record];
}

- (void)updateLabels {
  self.secondsElapsed++;
  NSInteger minutes = self.secondsElapsed / 60;
  NSInteger seconds = self.secondsElapsed % 60;
  self.timeLabel.text =
      [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)seconds];

  NSString *recordingText = @"Recording";
  for (NSInteger i = 0; i < self.recordingTextIndex; i++) {
    recordingText = [recordingText stringByAppendingString:@"."];
  }
  self.recordingLabel.text = recordingText;

  self.recordingTextIndex = (self.recordingTextIndex + 1) % 4;
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  [self stopRecord];
}

- (void)stopRecord {
  [self.audioRecorder stop];
  
  if (self.timer) {
    [self.timer invalidate];
    self.timer = nil;
  }
  
  if (self.save) {
    FlashThought *newThought = [[FlashThought alloc] initWithType:FlashThoughtTypeAudioFlashThought date:[NSDate date]];
    newThought.audioFilePath = [self audioRecordingPath].path;
    newThought.type = FlashThoughtTypeAudioFlashThought;
    
    [[FlashThoughtManager sharedManager] addThought:newThought];
  }
}

- (IBAction)okButtonDidClicked:(id)sender {
  self.save = YES;
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setupAudioRecorder {
  NSError *error = nil;
  [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryRecord error:&error];
  if (error) {
    NSLog(@"设置录音会话出错: %@", error.localizedDescription);
    return;
  }
  
  // 配置录音器
 NSURL *recordingURL = [self audioRecordingPath];
  NSDictionary *settings = @{
    AVFormatIDKey: @(kAudioFormatMPEG4AAC),
    AVSampleRateKey: @44100,
    AVNumberOfChannelsKey: @2,
  };
  
  self.audioRecorder = [[AVAudioRecorder alloc] initWithURL:recordingURL settings:settings error:&error];
  if (error) {
    NSLog(@"创建录音器出错: %@", error.localizedDescription);
    return;
  }
  
  self.audioRecorder.delegate = self;
}

- (NSURL *)audioRecordingPath {
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths objectAtIndex:0];
  NSString *filePath = [documentsDirectory stringByAppendingPathComponent:self.fileName];
  
  return [NSURL fileURLWithPath:filePath];
}


@end
