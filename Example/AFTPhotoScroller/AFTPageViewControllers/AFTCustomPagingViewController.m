//
//  AFTCustomPagingViewController.m
//  AFTPhotoScroller
//
//  Created by huangkun on 2017/1/23.
//  Copyright © 2017年 huangkun. All rights reserved.
//

#import "AFTCustomPagingViewController.h"
#import "AFTPageBar.h"

#define AFT_CUSTOM_PAGE_COLOR [UIColor colorWithRed:0.220 green:0.286 blue:0.361 alpha:1.00]

@interface AFTCustomPagingViewController () <AFTPagingScrollViewDelegate, AFTPageBarDataSource, AFTPageBarDelegate>
@property (nonatomic, strong) AFTPageBar *pageBar;
@property (nonatomic, assign) BOOL didPopAlert;
@end

@implementation AFTCustomPagingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // AFTPageBar should use auto layout as well,
    // but for demo, just simply set it's frame.
    
    CGRect pageBarFrame = self.view.bounds;
    pageBarFrame.size.height = 44;
    pageBarFrame.origin.y = self.view.bounds.size.height - pageBarFrame.size.height;

    _pageBar = [[AFTPageBar alloc] initWithFrame:pageBarFrame];
    _pageBar.delegate = self;
    _pageBar.dataSource = self;
    
    [self.view addSubview:_pageBar];
    
    
    [_pageBar reloadData];
    [_pageBar highlightButtonAtPageIndex:0];
    
    
    self.pagingView.delegate = self;
    self.pagingView.paddingBetweenPages = 6;
    self.pagingView.backgroundColor = AFT_CUSTOM_PAGE_COLOR;
    [self.pagingView reloadData];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(handleDeviceRotation)
                                               name:UIDeviceOrientationDidChangeNotification
                                             object:UIDevice.currentDevice];
}

- (void)updatePagingBackgroundColor {
    self.pagingView.backgroundColor = self.navBar.alpha > 0 ? UIColor.whiteColor : AFT_CUSTOM_PAGE_COLOR;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:UIDeviceOrientationDidChangeNotification
                                                object:UIDevice.currentDevice];
}

#pragma mark - AFTPagingScrollViewDelegate

- (void)pagingScrollView:(AFTPagingScrollView *)pagingScrollView didScrollToPageAtIndex:(NSInteger)pageIndex {
    [self.pageBar highlightButtonAtPageIndex:pageIndex];
}

- (BOOL)pagingScrollView:(AFTPagingScrollView *)pagingScrollView shouldDisplayPageAtIndex:(NSInteger)pageIndex {
    return [self shouldDisplayPageAtIndex:pageIndex];
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

#pragma mark - AFTPageBarDataSource

- (NSInteger)numberOfPagesInPageBar:(AFTPageBar *)pageBar {
    return self.images.count;
}

#pragma mark - AFTPageBarDelegate

- (void)pageBar:(AFTPageBar *)pageBar didSelectPageAtIndex:(NSInteger)pageIndex {
    [self.pagingView displayPageAtIndex:pageIndex];
}

- (BOOL)pageBar:(AFTPageBar *)pageBar shouldSelectPageAtIndex:(NSInteger)pageIndex {
    return [self shouldDisplayPageAtIndex:pageIndex];
}

#pragma mark - Rotation

- (void)handleDeviceRotation {
    self.pageBar.hidden = UIDeviceOrientationIsLandscape(UIDevice.currentDevice.orientation);
}

#pragma mark - Helper

- (BOOL)shouldDisplayPageAtIndex:(NSInteger)pageIndex {
    const NSInteger forbiddenPageIndex = 2;
    if (pageIndex == forbiddenPageIndex) {
        if (!self.didPopAlert) {
            self.didPopAlert = YES;
            
            NSString *message = [NSString stringWithFormat:@"You can't see page %@.", @(forbiddenPageIndex)];
            
            __weak typeof(self) _self = self;
            [self showAlertWithTitle:@"Oops" message:message dismissed:^{
                __strong typeof(_self) self = _self;
                self.didPopAlert = NO;
            }];
        }
        
        return NO;
    }
    return YES;
}

@end
