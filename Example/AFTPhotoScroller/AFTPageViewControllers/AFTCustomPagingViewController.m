//
//  AFTCustomPagingViewController.m
//  AFTPhotoScroller
//
//  Created by huangkun on 2017/1/23.
//  Copyright © 2017年 huangkun. All rights reserved.
//

#import "AFTCustomPagingViewController.h"
#import "AFTPageBar.h"

@interface AFTCustomPagingViewController () <AFTPagingScrollViewDelegate, AFTPageBarDataSource, AFTPageBarDelegate>
@property (nonatomic, strong) AFTPageBar *pageBar;
@end

@implementation AFTCustomPagingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
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
    [self.pagingView reloadData];
}

#pragma mark - AFTPagingScrollViewDelegate

- (void)pagingScrollView:(AFTPagingScrollView *)pagingScrollView didScrollToPageAtIndex:(NSInteger)pageIndex {
    [self.pageBar highlightButtonAtPageIndex:pageIndex];
}

#pragma mark - AFTPageBarDataSource

- (NSInteger)numberOfPagesInPageBar:(AFTPageBar *)pageBar {
    return self.images.count;
}

#pragma mark - AFTPageBarDelegate

- (void)pageBar:(AFTPageBar *)pageBar didSelectPageAtIndex:(NSInteger)pageIndex {
    [self.pagingView displayPageAtIndex:pageIndex];
}

@end
