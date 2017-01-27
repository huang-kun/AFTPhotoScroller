//
//  AFTNavigationBar.m
//  AFTNavigationBar
//
//  Created by huangkun on 2017/1/10.
//  Copyright © 2017年 huangkun. All rights reserved.
//

#import "AFTNavigationBar.h"

#define AFT_NAV_SYSTEM_TINT_COLOR [UIColor colorWithRed:0.188 green:0.482 blue:0.965 alpha:1.00]

@interface AFTNavigationBar ()
@property (nonatomic, strong) UIButton *backBarButton;
@property (nonatomic, strong) UILabel *titleLabel;
@end

@implementation AFTNavigationBar

static CGFloat const kAFTNavBarButtonSizeStandard = 44;
static CGFloat const kAFTNavBarButtonSizeCompact = 32;
__unused static CGFloat const kAFTNavBarHeight = 44;
__unused static CGFloat const kAFTStatusBarHeight = 20;

static NSString * const kAFTALConstraintID_NavBarHeight = @"kAFTALConstraintID_NavBarHeight";
static NSString * const kAFTALConstraintID_BarButtonHeight = @"kAFTALConstraintID_BarButtonHeight";

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    // setup
    self.backgroundColor = [UIColor colorWithRed:0.976 green:0.976 blue:0.976 alpha:1.00];
    
    // build interface
    [self buildInterface];
    
    // add notification
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(handleStatusBarOrientationChange:)
                                               name:UIApplicationWillChangeStatusBarFrameNotification
                                             object:UIApplication.sharedApplication];
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:UIApplicationWillChangeStatusBarFrameNotification
                                                object:UIApplication.sharedApplication];
}

- (void)buildInterface {
    // back button
    _backBarButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _backBarButton.tintColor = AFT_NAV_SYSTEM_TINT_COLOR;
    [_backBarButton setImage:[UIImage imageNamed:@"aft_back_final"] forState:UIControlStateNormal];
    [_backBarButton addTarget:self action:@selector(handlePopAction:) forControlEvents:UIControlEventTouchUpInside];
    
    UIEdgeInsets imageEdgeInsets = _backBarButton.imageEdgeInsets;
    imageEdgeInsets.left = 8;
    _backBarButton.imageEdgeInsets = imageEdgeInsets;
    
    [self addSubview:_backBarButton];
    
    // title label
    _titleLabel = [UILabel new];
    _titleLabel.numberOfLines = 1;
    _titleLabel.textColor = AFT_NAV_SYSTEM_TINT_COLOR;
    _titleLabel.font = [UIFont boldSystemFontOfSize:17];
    _titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    
    [self addSubview:_titleLabel];
    
    // setup constraints
    [self setupConstraints];
}

#pragma mark - Accessors

- (void)setTitle:(NSString *)title {
    _title = title.copy;
    _titleLabel.text = title;
}

- (void)setRightBarButton:(UIButton *)rightBarButton {
    [_rightBarButton removeFromSuperview];
    _rightBarButton = rightBarButton;
    [self addSubview:_rightBarButton];
    [self setupRightBarButtonConstraints];
    
    if (_rightBarButton.buttonType == UIButtonTypeSystem) {
        _rightBarButton.tintColor = AFT_NAV_SYSTEM_TINT_COLOR;
        _rightBarButton.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    }
}

#pragma mark - Auto Layout

- (void)setupConstraints {
    [self setupNavBarHeightConstraint];
    [self setupBackButtonConstraints];
    [self setupTitleLabelConstraints];
}

- (void)setupNavBarHeightConstraint {
    CGFloat totalBarHeight = 64;
    if (UIDeviceOrientationIsLandscape(UIDevice.currentDevice.orientation)) {
        totalBarHeight = 32;
    }
    
    NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:totalBarHeight];
    [self addConstraint:height];
    
    height.identifier = kAFTALConstraintID_NavBarHeight;
}

- (void)setupBackButtonConstraints {
    _backBarButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    CGFloat buttonHeight = kAFTNavBarButtonSizeStandard;
    if (UIDeviceOrientationIsLandscape(UIDevice.currentDevice.orientation)) {
        buttonHeight = kAFTNavBarButtonSizeCompact;
    }
    
    NSLayoutConstraint *left = [NSLayoutConstraint constraintWithItem:_backBarButton attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0];
    NSLayoutConstraint *bottom = [NSLayoutConstraint constraintWithItem:_backBarButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
    NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:_backBarButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1.0 constant:kAFTNavBarButtonSizeStandard];
    NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:_backBarButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:buttonHeight];
    height.identifier = kAFTALConstraintID_BarButtonHeight;
    
    [self addConstraints:@[left, bottom, width, height]];
}

- (void)setupRightBarButtonConstraints {
    _rightBarButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    CGFloat buttonHeight = kAFTNavBarButtonSizeStandard;
    if (UIDeviceOrientationIsLandscape(UIDevice.currentDevice.orientation)) {
        buttonHeight = kAFTNavBarButtonSizeCompact;
    }
    
    NSLayoutConstraint *right = [NSLayoutConstraint constraintWithItem:_rightBarButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0 constant:-8.0];
    NSLayoutConstraint *bottom = [NSLayoutConstraint constraintWithItem:_rightBarButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
    NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:_rightBarButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:buttonHeight];
    height.identifier = kAFTALConstraintID_BarButtonHeight;

    [self addConstraints:@[right, bottom, height]];
}

- (void)setupTitleLabelConstraints {
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSLayoutConstraint *left = [NSLayoutConstraint constraintWithItem:_titleLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0 constant:kAFTNavBarButtonSizeStandard];
    NSLayoutConstraint *right = [NSLayoutConstraint constraintWithItem:_titleLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0 constant:-kAFTNavBarButtonSizeStandard];
    NSLayoutConstraint *centerY = [NSLayoutConstraint constraintWithItem:_titleLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_backBarButton attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0];
    
    [self addConstraints:@[left, right, centerY]];
}

#pragma mark - Target / Action

- (void)handlePopAction:(UIButton *)button {
    if ([self.delegate respondsToSelector:@selector(navigationBar:didTapBackBarButton:)]) {
        [self.delegate navigationBar:self didTapBackBarButton:button];
    }
}

#pragma mark - Notifications

- (void)handleStatusBarOrientationChange:(NSNotification *)notification {
    BOOL isLandscape = (UIDeviceOrientationIsLandscape(UIDevice.currentDevice.orientation));
    __unused CGRect statusBarFrame = [notification.userInfo[UIApplicationStatusBarFrameUserInfoKey] CGRectValue];

    for (NSLayoutConstraint *constraint in self.constraints) {
        // adjust navigation bar height
        if ([constraint.identifier isEqualToString:kAFTALConstraintID_NavBarHeight]) {
            constraint.constant = isLandscape ? 32 : 64;
        }
        // adjust bar button height
        if ([constraint.identifier isEqualToString:kAFTALConstraintID_BarButtonHeight]) {
            constraint.constant = isLandscape ? kAFTNavBarButtonSizeCompact : kAFTNavBarButtonSizeStandard;
        }
    }
}

@end
