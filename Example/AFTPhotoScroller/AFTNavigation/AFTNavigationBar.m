//
//  AFTNavigationBar.m
//  AFTNavigationBar
//
//  Created by huangkun on 2017/1/10.
//  Copyright © 2017年 huangkun. All rights reserved.
//

#import "AFTNavigationBar.h"

@interface AFTNavigationBar ()
@property (nonatomic, strong) UIButton *backBarButton;
@property (nonatomic, assign) CGRect navigationBarFrame;
@end

@implementation AFTNavigationBar

- (instancetype)initWithTitle:(NSString *)title {
    CGRect navFrame = UIScreen.mainScreen.bounds;
    navFrame.size.height = 64;
    
    self = [super initWithFrame:navFrame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0.976 green:0.976 blue:0.976 alpha:1.00];
        [self buildInterfaceWithTitle:title];
    }
    return self;
}

- (void)buildInterfaceWithTitle:(NSString *)title {
    CGRect navBarFrame = self.bounds;
    navBarFrame.origin.y = 20;
    navBarFrame.size.height = 44;
   
    // back button
    CGRect backBarButtonFrame = navBarFrame;
    backBarButtonFrame.size.width = backBarButtonFrame.size.height;
    
    UIButton *backBarButton = [UIButton buttonWithType:UIButtonTypeSystem];
    backBarButton.frame = backBarButtonFrame;
    [backBarButton setImage:[UIImage imageNamed:@"aft_back_final"] forState:UIControlStateNormal];
    [backBarButton addTarget:self action:@selector(handlePopAction:) forControlEvents:UIControlEventTouchUpInside];
    [backBarButton setTintColor:[UIColor colorWithRed:0.188 green:0.482 blue:0.965 alpha:1.00]];
    
    UIEdgeInsets imageEdgeInsets = backBarButton.imageEdgeInsets;
    imageEdgeInsets.left = 8;
    backBarButton.imageEdgeInsets = imageEdgeInsets;
    
    [self addSubview:backBarButton];
    
    // title label
    UILabel *titleLabel = [UILabel new];
    titleLabel.text = title;
    titleLabel.numberOfLines = 1;
    titleLabel.textColor = [UIColor colorWithRed:0.188 green:0.482 blue:0.965 alpha:1.00];
    titleLabel.font = [UIFont boldSystemFontOfSize:17];
    titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [titleLabel sizeToFit];
    [self addSubview:titleLabel];
    
    CGRect titleLabelFrame = titleLabel.frame;
    CGFloat maxLabelWidth = navBarFrame.size.width - backBarButtonFrame.size.width * 2 - 5;
    if (titleLabelFrame.size.width > maxLabelWidth) {
        titleLabelFrame.size.width = maxLabelWidth;
    }
    titleLabelFrame.origin.x = (navBarFrame.size.width - titleLabelFrame.size.width) / 2;
    titleLabelFrame.origin.y = (navBarFrame.size.height - titleLabelFrame.size.height) / 2 + navBarFrame.origin.y;
    
    titleLabel.frame = titleLabelFrame;
    
    // 引用
    self.backBarButton = backBarButton;
    self.navigationBarFrame = navBarFrame;
}

- (void)setRightBarButton:(UIButton *)rightBarButton {
    [_rightBarButton removeFromSuperview];
    _rightBarButton = rightBarButton;
    
    CGRect rightBarButtonFrame = self.backBarButton.frame;
    rightBarButtonFrame.origin.x = self.navigationBarFrame.size.width - rightBarButtonFrame.size.width;
    
    _rightBarButton.frame = rightBarButtonFrame;
    [self addSubview:_rightBarButton];
}

- (void)handlePopAction:(UIButton *)button {
    if ([self.delegate respondsToSelector:@selector(navigationBar:didTapBackBarButton:)]) {
        [self.delegate navigationBar:self didTapBackBarButton:button];
    }
}

@end
