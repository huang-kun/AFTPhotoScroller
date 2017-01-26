//
//  AFTProgressBar.m
//  AFTPhotoScroller
//
//  Created by huangkun on 2017/1/26.
//  Copyright © 2017年 huangkun. All rights reserved.
//

#import "AFTProgressBar.h"

@interface AFTProgressBar ()
@property (nonatomic, strong) UILabel *progressLabel;
@property (nonatomic, strong) UIView *animatedProgressBar;
@end

@implementation AFTProgressBar

static CGFloat const kAFTProgressBarHeight = 74;

+ (instancetype)largeSizedProgressBar {
    CGRect screenBounds = UIScreen.mainScreen.bounds;
    
    CGRect barFrame = screenBounds;
    barFrame.size.height = kAFTProgressBarHeight;
    barFrame.origin.y = screenBounds.size.height - kAFTProgressBarHeight;
    
    AFTProgressBar *progressBar = [[AFTProgressBar alloc] initWithFrame:barFrame];
    [progressBar buildInterface];
    progressBar.progress = 0;
    
    return progressBar;
}

- (void)buildInterface {
    _animatedProgressBar = [[UIView alloc] initWithFrame:self.bounds];
    _animatedProgressBar.backgroundColor = UIColor.greenColor;
    [self addSubview:_animatedProgressBar];
    
    _progressLabel = [[UILabel alloc] initWithFrame:self.bounds];
    _progressLabel.textAlignment = NSTextAlignmentCenter;
    _progressLabel.font = [UIFont systemFontOfSize:24];
    _progressLabel.textColor = UIColor.darkGrayColor;
    _progressLabel.text = @"downloading ...";
    [self addSubview:_progressLabel];
}

- (void)setProgress:(double)progress {
    _progress = progress;
    
    CGRect barFrame = _animatedProgressBar.frame;
    barFrame.origin.x = 0 - barFrame.size.width;
    barFrame.origin.x += barFrame.size.width * progress;
    _animatedProgressBar.frame = barFrame;
}

@end
