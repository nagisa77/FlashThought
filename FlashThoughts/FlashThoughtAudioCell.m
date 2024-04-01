//
//  FlashThoughtAudioCell.m
//  FlashThoughts
//
//  Created by tim on 2024/4/1.
//

#import "FlashThoughtAudioCell.h"
@interface FlashThoughtAudioCell ()

@property(strong, nonatomic) AVAudioPlayer *audioPlayer;
@property(strong, nonatomic) NSTimer *progressTimer;

@property IBOutlet UIButton *playButton;
@property IBOutlet UIProgressView *progressView;
@property IBOutlet UILabel *timeLabel;

@end

@implementation FlashThoughtAudioCell

- (void)startProgressTimer {
  if (self.progressTimer == nil) {
    self.progressTimer =
        [NSTimer scheduledTimerWithTimeInterval:0.05
                                         target:self
                                       selector:@selector(updateProgress)
                                       userInfo:nil
                                        repeats:YES];
  }
}

- (void)stopProgressTimer {
  [self.progressTimer invalidate];
  self.progressTimer = nil;
}

- (void)updateProgress {
  float progress = self.audioPlayer.currentTime / self.audioPlayer.duration;
  self.progressView.progress = progress;

  // 更新时间标签
  int totalSeconds = (int)self.audioPlayer.currentTime;
  int minutes = totalSeconds / 60;
  int seconds = totalSeconds % 60;
  self.timeLabel.text =
      [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
}

- (void)setupAudioPlayerWithURL:(NSURL *)fileURL {
  NSError *error = nil;

  self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL
                                                            error:&error];
  if (error) {
    NSLog(@"Error in audioPlayer: %@", [error localizedDescription]);
  } else {
    self.audioPlayer.delegate = self;
    [self.audioPlayer prepareToPlay];
  }

  [self.timeLabel setText:@"00:00"];
  self.progressView.progress = 0; // Reset progress view.
}

- (IBAction)playButtonDidClicked:(id)sender {
  if (self.audioPlayer.isPlaying) {
    [self.playButton setImage:[UIImage systemImageNamed:@"play.fill"]
                     forState:UIControlStateNormal];
    [self.audioPlayer pause];
    [self stopProgressTimer];
  } else {
    [self.playButton setImage:[UIImage systemImageNamed:@"pause.fill"]
                     forState:UIControlStateNormal];
    [self.audioPlayer play];
    [self startProgressTimer]; // Start timer when playing.
  }
}

- (void)prepareForReuse {
  [super prepareForReuse];
  [self stopProgressTimer];
  self.progressView.progress = 0;
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
  if (flag) {
    [self.playButton setImage:[UIImage systemImageNamed:@"play.fill"] forState:UIControlStateNormal]; // Reset play button to "play" icon.
    [self stopProgressTimer]; // Stop the timer.
    [self.timeLabel setText:@"00:00"]; // Reset time label.
    self.progressView.progress = 0; // Reset progress view.
  }
}


@end
