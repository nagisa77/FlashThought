//
//  RoundedButtonWithShadow.m
//  FlashThoughts
//
//  Created by tim on 2024/3/27.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface RoundedButtonWithShadow : UIButton
@end

@implementation RoundedButtonWithShadow

- (void)awakeFromNib {
  [super awakeFromNib];

  self.layer.cornerRadius = self.frame.size.height / 2;
  self.layer.shadowColor = [UIColor blackColor].CGColor;
  self.layer.masksToBounds = NO;

  // Creating a rounded rect path for the shadow.
  UIBezierPath *shadowPath =
      [UIBezierPath bezierPathWithRoundedRect:self.bounds
                                 cornerRadius:self.layer.cornerRadius];
  self.layer.shadowPath = shadowPath.CGPath;

  self.layer.shadowOffset = CGSizeMake(0.0, 0.0);
  self.layer.shadowOpacity = 0.6;
  self.layer.shadowRadius = 30.0;
}

- (void)layoutSubviews {
  [super layoutSubviews];
}

@end
