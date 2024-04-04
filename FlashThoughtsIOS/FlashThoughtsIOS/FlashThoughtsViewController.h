//
//  ViewController.h
//  FlashThoughts
//
//  Created by tim on 2024/3/26.
//

#import "LoginService.h"
#import <FlashThoughtPlatform/FlashThoughtManager.h>
#import <UIKit/UIKit.h>

@interface FlashThoughtsViewController
    : UIViewController <UITableViewDelegate, UITableViewDataSource,
                        UIContextMenuInteractionDelegate,
                        FlashThoughtManagerDelegate, UIScrollViewDelegate,
                        LoginServiceDelegate>

@end
