//
//  NewFlashThoughtViewController.m
//  FlashThoughts
//
//  Created by tim on 2024/3/27.
//

#import "FlashThoughtManager.h"
#import "NewFlashThoughtsViewController.h"

#define DEFAULT_TEXT @"Write ur flash thought..."

@implementation NewFlashThoughtsViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.textView.delegate = self;
  [self.view addSubview:self.textView];

  self.placeholderLabel = [[UILabel alloc]
      initWithFrame:CGRectMake(5, 0, self.textView.frame.size.width, 40)];
  self.placeholderLabel.text = DEFAULT_TEXT;
  self.placeholderLabel.textColor = [UIColor lightGrayColor];
  [self.textView addSubview:self.placeholderLabel];

  self.placeholderLabel.hidden = NO;
}

#pragma mark - UITextViewDelegate Methods

- (void)textViewDidBeginEditing:(UITextView *)textView {
  self.placeholderLabel.hidden = textView.text.length > 0;
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [self.textView becomeFirstResponder];
}

- (void)textViewDidChange:(UITextView *)textView {
  self.placeholderLabel.hidden = textView.text.length > 0;
}

- (IBAction)cancelButtonDidClicked:(id)sender {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)confirmButtonDidClicked:(id)sender {
  FlashThought *fs = [[FlashThought alloc] init];
  fs.content = self.textView.text;
  fs.date = [NSDate date];
  [[FlashThoughtManager sharedManager] addThought:fs];
  [self dismissViewControllerAnimated:YES completion:nil];
}

@end
