//
//  NewFlashThoughtsViewController.h
//  FlashThoughts
//
//  Created by tim on 2024/3/27.
//

#ifndef NewFlashThoughtsViewController_h
#define NewFlashThoughtsViewController_h
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NewFlashThoughtsViewController
    : UIViewController <UITextViewDelegate>
@property(weak, nonatomic) IBOutlet UITextView *textView;

@property(strong, nonatomic) UILabel *placeholderLabel;

@end

#endif /* NewFlashThoughtsViewController_h */
