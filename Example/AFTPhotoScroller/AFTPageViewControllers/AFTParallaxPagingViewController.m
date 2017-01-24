//
//  AFTParallaxPagingViewController.m
//  AFTPhotoScroller
//
//  Created by huangkun on 2017/1/23.
//  Copyright © 2017年 huangkun. All rights reserved.
//

#import "AFTParallaxPagingViewController.h"

@interface AFTParallaxPagingViewController ()
@end

@implementation AFTParallaxPagingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.pagingView.parallaxScrollingEnabled = YES;
    [self.pagingView reloadData];
}

#pragma mark - AFTPagingScrollViewDelegate

- (CGFloat)paddingBetweenPagesInPagingScrollView:(AFTPagingScrollView *)pagingScrollView {
    // If you call setParallaxScrollingEnabled: to YES and do not implement this method,
    // then the default parallax padding will be 20. You can implement this method and
    // modify it here.
    return 18;
}

@end
