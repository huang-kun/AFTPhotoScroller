//
//  AFTPagingBaseViewController.m
//  AFTPhotoScroller
//
//  Created by huangkun on 2017/1/23.
//  Copyright © 2017年 huangkun. All rights reserved.
//

#import "AFTPagingBaseViewController.h"
#import "AFTPushAnimatedTransitioning.h"

@interface AFTPagingBaseViewController ()
@property (nonatomic, strong) AFTPagingScrollView *pagingView;
@property (nonatomic, strong) AFTNavigationBar *navBar;
@property (nonatomic, strong) AFTPushAnimatedTransitioning *pushTransitioning;
@end

@implementation AFTPagingBaseViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.pushTransitioning = [[AFTPushAnimatedTransitioning alloc] initWithPresentedViewController:self];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.pushTransitioning = [[AFTPushAnimatedTransitioning alloc] initWithPresentedViewController:self];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;

    _singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap)];
    [self.view addGestureRecognizer:_singleTap];
    
    _navBar = [[AFTNavigationBar alloc] initWithTitle:self.title];
    _navBar.delegate = self;
    [self.view addSubview:_navBar];
    
    _pagingView = [[AFTPagingScrollView alloc] initWithFrame:self.view.bounds];
    _pagingView.delegate = self;
    _pagingView.dataSource = self;
    [self.view addSubview:_pagingView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.view bringSubviewToFront:self.navBar];
}

- (void)handleSingleTap {
    [UIView animateWithDuration:0.2 animations:^{
        self.navBar.alpha = (CGFloat)!(BOOL)self.navBar.alpha;
    }];
}

- (void)hideNavigationBar {
    if (self.navBar.alpha == 0) {
        return;
    }
    [UIView animateWithDuration:0.2 animations:^{
        self.navBar.alpha = 0;
    }];
}

#pragma mark - AFTNavigationBarDelegate

- (void)navigationBar:(AFTNavigationBar *)navigationBar didTapBackBarButton:(UIButton *)backBarButton {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - AFTPagingScrollViewDataSource

- (NSInteger)numberOfPagesInPagingScrollView:(AFTPagingScrollView *)pagingScrollView {
    return self.images.count;
}

- (UIImage *)pagingScrollView:(AFTPagingScrollView *)pagingScrollView imageForPageAtIndex:(NSInteger)pageIndex {
    return self.images[pageIndex];
}

#pragma mark - AFTPagingScrollViewDelegate

- (CGFloat)paddingBetweenPagesInPagingScrollView:(AFTPagingScrollView *)pagingScrollView {
    return 8;
}

- (void)pagingScrollView:(AFTPagingScrollView *)pagingScrollView imageScrollView:(UIScrollView *)imageScrollView didEnableZoomingTapGesture:(UITapGestureRecognizer *)zoomingTap {
    [self.singleTap requireGestureRecognizerToFail:zoomingTap]; // Single tap will delay its action until double tap recognizing is failed.
}

- (void)pagingScrollViewWillBeginPaging:(AFTPagingScrollView *)pagingScrollView {
    [self hideNavigationBar];
}

- (void)pagingScrollView:(AFTPagingScrollView *)pagingScrollView imageScrollViewDidScrollImage:(UIScrollView *)imageScrollView atPageIndex:(NSInteger)pageIndex {
    [self hideNavigationBar];
}

- (void)pagingScrollView:(AFTPagingScrollView *)pagingScrollView imageScrollViewWillBeginZooming:(UIScrollView *)imageScrollView atPageIndex:(NSInteger)pageIndex {
    [self hideNavigationBar];
}

@end
