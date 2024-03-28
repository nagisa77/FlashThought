//
//  ViewController.h
//  FlashThoughts
//
//  Created by tim on 2024/3/26.
//

#import "FlashThoughtManager.h"
#import <UIKit/UIKit.h>

@interface FlashThoughtsViewController
    : UIViewController <UITableViewDelegate, UITableViewDataSource,
                        FlashThoughtManagerDelegate>

@end
