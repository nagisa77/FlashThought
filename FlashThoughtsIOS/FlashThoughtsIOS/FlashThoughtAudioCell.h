//
//  FlashThoughtAudioCell.h
//  FlashThoughts
//
//  Created by tim on 2024/4/1.
//

#ifndef FlashThoughtAudioCell_h
#define FlashThoughtAudioCell_h

#import "AudioPlayerManager.h"
#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface FlashThoughtAudioCell
    : UITableViewCell <AVAudioPlayerDelegate, AudioPlayerManagerDelegate>

@property(weak, nonatomic) IBOutlet UILabel *dateLabel;

- (void)setupAudioPlayerWithURL:(NSURL *)url;

@end

#endif /* FlashThoughtAudioCell_h */
