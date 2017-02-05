//
//  AFTPagingBaseViewController.m
//  AFTPhotoScroller
//
//  Created by huangkun on 2017/1/23.
//  Copyright © 2017年 huangkun. All rights reserved.
//

#import "AFTPagingBaseViewController.h"
#import "AFTPushAnimatedTransitioning.h"

@interface AFTPagingBaseViewController () <UIAlertViewDelegate>
@property (nonatomic, strong) AFTPagingScrollView *pagingView;
@property (nonatomic, strong) AFTNavigationBar *navBar;
@property (nonatomic, strong) AFTPushAnimatedTransitioning *pushTransitioning;
@property (nonatomic, copy) void(^dismissBlock)(void);
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

- (void)dealloc {
    NSLog(@"%@ dealloc", self);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.blackColor;
    self.automaticallyAdjustsScrollViewInsets = NO;

    // single tap to show or hide navigation bar
    _singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap)];
    [self.view addGestureRecognizer:_singleTap];
    
    // navigation bar
    _navBar = [[AFTNavigationBar alloc] init];
    _navBar.delegate = self;
    _navBar.title = self.title;
    [self.view addSubview:_navBar];
    
    // guide button
    UIButton *rightBarButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [rightBarButton setTitle:@"Guide" forState:UIControlStateNormal];
    [rightBarButton addTarget:self action:@selector(handleRightBarButtonTap) forControlEvents:UIControlEventTouchUpInside];
    _navBar.rightBarButton = rightBarButton;
    
    // paging view
    _pagingView = [[AFTPagingScrollView alloc] init];
    _pagingView.backgroundColor = UIColor.whiteColor;
    _pagingView.delegate = self;
    _pagingView.dataSource = self;
    [self.view addSubview:_pagingView];
    
    // setup auto layout
    [self setupConstraints];
    [self.view layoutIfNeeded];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.view bringSubviewToFront:self.navBar];
}

- (void)handleSingleTap {
    [UIView animateWithDuration:0.2 animations:^{
        self.navBar.alpha = (CGFloat)!(BOOL)self.navBar.alpha;
        [self updatePagingBackgroundColor];
    }];
}

- (void)hideNavigationBar {
    if (self.navBar.alpha == 0) {
        return;
    }
    [UIView animateWithDuration:0.2 animations:^{
        self.navBar.alpha = 0;
        [self updatePagingBackgroundColor];
    }];
}

- (void)updatePagingBackgroundColor {
    self.pagingView.backgroundColor = self.navBar.alpha > 0 ? UIColor.whiteColor : UIColor.blackColor;
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

- (void)pagingScrollView:(AFTPagingScrollView *)pagingScrollView imageScrollView:(UIScrollView *)imageScrollView didEnableZoomingTapGesture:(UITapGestureRecognizer *)zoomingTap {
    [self.singleTap requireGestureRecognizerToFail:zoomingTap]; // Single tap will delay its action until double tap recognizing is failed.
}

#pragma mark - Rotation

- (BOOL)shouldAutorotate {
    return YES;
}

// iOS 8+
#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_8_0)

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
    [self.pagingView saveCurrentStatesForRotation];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [self.pagingView restoreStatesForRotationInSize:size];
}

#else

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self.pagingView saveCurrentStatesForRotation];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self.pagingView restoreStatesForRotation];
}

#endif // iOS Version


#pragma mark - Auto layout

- (void)setupConstraints {
    [self setupNavigationBarConstraints];
    [self setupPagingViewConstraints];
}

- (void)setupNavigationBarConstraints {
    self.navBar.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSLayoutConstraint *top = [NSLayoutConstraint constraintWithItem:self.navBar attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
    NSLayoutConstraint *left = [NSLayoutConstraint constraintWithItem:self.navBar attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0];
    NSLayoutConstraint *right = [NSLayoutConstraint constraintWithItem:self.navBar attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0];
    
    [self.view addConstraints:@[top, left, right]];
}

- (void)setupPagingViewConstraints {
    self.pagingView.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSLayoutConstraint *top = [NSLayoutConstraint constraintWithItem:self.pagingView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
    NSLayoutConstraint *left = [NSLayoutConstraint constraintWithItem:self.pagingView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0];
    NSLayoutConstraint *bottom = [NSLayoutConstraint constraintWithItem:self.pagingView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
    NSLayoutConstraint *right = [NSLayoutConstraint constraintWithItem:self.pagingView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0];
    
    [self.view addConstraints:@[top, left, bottom, right]];
}

#pragma mark - Target / Action

- (void)handleRightBarButtonTap {
    [self showAlertWithTitle:@"Guide" message:@"You can swipe between pages, single tap to hide/show navigation bar, double tap or pinch to zoom image, and rotate device if you like."];
}

#pragma mark - Alert

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    [self showAlertWithTitle:title message:message dismissed:nil];
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message dismissed:(void(^)(void))dismissed {
    // iOS 8+
#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_8_0)
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [alert dismissViewControllerAnimated:YES completion:nil];
        if (dismissed) dismissed();
    }];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
    
#else
    
    self.dismissBlock = dismissed;
    [[[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
    
#endif
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0 && self.dismissBlock) {
        self.dismissBlock();
    }
}

@end
