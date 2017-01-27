//
//  AFTNormalPagingViewController.m
//  AFTPhotoScroller
//
//  Created by huangkun on 2017/1/23.
//  Copyright © 2017年 huangkun. All rights reserved.
//

#import "AFTNormalPagingViewController.h"

@interface AFTNormalPagingViewController ()
@end

@implementation AFTNormalPagingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.pagingView.parallaxScrollingEnabled = YES;
    [self.pagingView reloadData];
}

@end
