//
//  AFTNavigationBar.h
//  AFTNavigationBar
//
//  Created by huangkun on 2017/1/10.
//  Copyright © 2017年 huangkun. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class AFTNavigationBar;

@protocol AFTNavigationBarDelegate <NSObject>
- (void)navigationBar:(AFTNavigationBar *)navigationBar didTapBackBarButton:(UIButton *)backBarButton; ///< 点击返回
@end

/**
 包含了status bar高度的navigation bar
 */
@interface AFTNavigationBar : UIView

@property (nonatomic, copy) NSString *title; ///< 标题
@property (nonatomic, readonly, strong) UIButton *backBarButton; ///< 导航栏的返回按钮
@property (nullable, nonatomic, strong) UIButton *rightBarButton; ///< 导航栏的右侧按钮
@property (nonatomic, weak) id <AFTNavigationBarDelegate> delegate; ///< 代理

@end

NS_ASSUME_NONNULL_END
