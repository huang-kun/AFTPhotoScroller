//
//  AFTPageBar.h
//  AFTPhotoScroller
//
//  Created by huangkun on 2016/12/30.
//  Copyright © 2016年 huangkun. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AFTPageBar;

NS_ASSUME_NONNULL_BEGIN

@protocol AFTPageBarDataSource <NSObject>
- (NSInteger)numberOfPagesInPageBar:(AFTPageBar *)pageBar; ///< 总页数
@end

@protocol AFTPageBarDelegate <NSObject>
- (void)pageBar:(AFTPageBar *)pageBar didSelectPageAtIndex:(NSInteger)pageIndex; /// 选择页数
@optional
- (BOOL)pageBar:(AFTPageBar *)pageBar shouldSelectPageAtIndex:(NSInteger)pageIndex; /// 是否允许选择页数
@end


/// 页数选择栏
@interface AFTPageBar : UIView

@property (nonatomic, readonly) UIScrollView *backingScrollView;
@property (nonatomic, weak) id <AFTPageBarDelegate> delegate; ///< 代理
@property (nonatomic, weak) id <AFTPageBarDataSource> dataSource; ///< 数据源
@property (nonatomic, strong) UIColor *pageButtonNormalTitleColor; ///< 页数按钮文字颜色
@property (nonatomic, strong) UIColor *pageButtonSelectedTitleColor; ///< 页数按钮文字的选中颜色
@property (nonatomic, strong) UIColor *pageButtonSelectedBackgroundColor; ///< 页数按钮背景色

- (void)selectPageAtIndex:(NSInteger)pageIndex; ///< 选中页数，会触发代理方法 (It will trigger -should/didSelectPageAtIndex: delegate methods)
- (void)highlightButtonAtPageIndex:(NSInteger)pageIndex; ///< 点亮按钮，不会触发代理方法 (It will not trigger any delegate methods)

- (void)reloadData;

@end

NS_ASSUME_NONNULL_END
