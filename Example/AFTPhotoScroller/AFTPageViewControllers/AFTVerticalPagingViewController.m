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
    self.pagingView.navigationOrientation = AFTPagingScrollViewNavigationOrientationVertical;
    [self.pagingView reloadData];
}

@end
