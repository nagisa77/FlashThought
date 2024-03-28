//
//  FlashThoughtCell.h
//  FlashThoughts
//
//  Created by tim on 2024/3/28.
//

#ifndef FlashThoughtCell_h
#define FlashThoughtCell_h
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface FlashThoughtCell : UITableViewCell

@property(weak, nonatomic) IBOutlet UILabel *contentLabel;

@property(weak, nonatomic) IBOutlet UILabel *dateLabel;

@end

#endif /* FlashThoughtCell_h */
