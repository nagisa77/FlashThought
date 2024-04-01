//
//  FlashThoughtAudioCell.h
//  FlashThoughts
//
//  Created by tim on 2024/4/1.
//

#ifndef FlashThoughtAudioCell_h
#define FlashThoughtAudioCell_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface FlashThoughtAudioCell : UITableViewCell<AVAudioPlayerDelegate>

@property(weak, nonatomic) IBOutlet UILabel *timeLabel;

@property(weak, nonatomic) IBOutlet UILabel *dateLabel;

@end

#endif /* FlashThoughtAudioCell_h */
