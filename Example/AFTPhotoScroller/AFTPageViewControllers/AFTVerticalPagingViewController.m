//
//  AFTVerticalPagingViewController.m
//  AFTPhotoScroller
//
//  Created by huangkun on 2017/1/23.
//  Copyright © 2017年 huangkun. All rights reserved.
//

#import "AFTVerticalPagingViewController.h"

@interface AFTVerticalPagingViewController ()
@end

@implementation AFTVerticalPagingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.pagingView.delegate = self;
    self.pagingView.parallaxScrollingEnabled = YES;
    self.pagingView.navigationOrientation = AFTPagingScrollViewNavigationOrientationVertical;
    [self.pagingView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (UIDeviceOrientationIsPortrait(UIDevice.currentDevice.orientation)) {
        [self showAlertWithTitle:@"What's now?" message:@"Rotate your device to landscape, then you can see the parallax effect."];
    }
}

#pragma mark - AFTPagingScrollViewDelegate

- (CGFloat)paddingBetweenPagesInPagingScrollView:(AFTPagingScrollView *)pagingScrollView {
    // If you call setParallaxScrollingEnabled: to YES and do not implement this method,
    // then the default parallax padding will be 20. You can implement this method and
    // modify it here.
    return 18.0;
}

@end
