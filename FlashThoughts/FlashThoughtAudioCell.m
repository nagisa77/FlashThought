//
//  FlashThoughtAudioCell.m
//  FlashThoughts
//
//  Created by tim on 2024/4/1.
//

#import "FlashThoughtAudioCell.h"
@interface FlashThoughtAudioCell ()

@property (strong, nonatomic) AVAudioPlayer *audioPlayer;

@end

@implementation FlashThoughtAudioCell

- (void)setupAudioPlayerWithFile:(NSString *)fileName fileType:(NSString *)fileType {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:fileName ofType:fileType];
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    NSError *error = nil;

    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:&error];
    if (error) {
        NSLog(@"Error in audioPlayer: %@", [error localizedDescription]);
    } else {
        self.audioPlayer.delegate = self;
        [self.audioPlayer prepareToPlay];
    }
}

@end
