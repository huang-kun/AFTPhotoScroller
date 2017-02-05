//
//  AFTPagingBaseViewController.h
//  AFTPhotoScroller
//
//  Created by huangkun on 2017/1/23.
//  Copyright © 2017年 huangkun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AFTNavigationBar.h"
#import <AFTPhotoScroller/AFTPagingScrollView.h>

@interface AFTPagingBaseViewController : UIViewController <AFTNavigationBarDelegate, AFTPagingScrollViewDataSource, AFTPagingScrollViewDelegate>

/// page scroll view
@property (nonatomic, readonly, strong) AFTPagingScrollView *pagingView;

/// images for paging scroll.
@property (nonatomic, strong) NSArray <UIImage *> *images;

/// single tap for hide / show bar
@property (nonatomic, strong) UITapGestureRecognizer *singleTap;

/// Navigation bar (Fake)
@property (nonatomic, readonly, strong) AFTNavigationBar *navBar;

/// Single tap action which hides navigationBar by default implementation
- (void)handleSingleTap;

/// Hide navigation bar if needed with fade out animation.
- (void)hideNavigationBar;

/// Show simple alert view.
- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message;
- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message dismissed:(void(^)(void))dismissed;

/// Update background color. Default is white / black.
- (void)updatePagingBackgroundColor;

@end
