//
//  AFTPageBar.m
//  AFTPhotoScroller
//
//  Created by huangkun on 2016/12/30.
//  Copyright © 2016年 huangkun. All rights reserved.
//

#import "AFTPageBar.h"

@interface AFTPageBar ()
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIColor *pageButtonNormalBackgroundColor;
@end

@implementation AFTPageBar

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0.976 green:0.976 blue:0.976 alpha:1.00];
        _pageButtonNormalTitleColor = [UIColor colorWithRed:0.588 green:0.616 blue:0.651 alpha:1.00];
        _pageButtonSelectedTitleColor = UIColor.whiteColor;
        _pageButtonNormalBackgroundColor = self.backgroundColor;
        _pageButtonSelectedBackgroundColor = UIColor.lightGrayColor;
        
        _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.alwaysBounceVertical = NO;
        
        [self addSubview:_scrollView];
    }
    return self;
}

- (UIScrollView *)backingScrollView {
    return _scrollView;
}

- (void)reloadData {
    for (UIView *subview in _scrollView.subviews) {
        if ([subview isKindOfClass:UIButton.self]) {
            [subview removeFromSuperview];
        }
    }
    
    CGFloat containerHeight = self.bounds.size.height;
    CGFloat buttonSize = containerHeight * 1.0;
    CGFloat insetY = (containerHeight - buttonSize) / 2;
    CGFloat insetX = insetY * 2;
    CGFloat originX = insetX;
    
    for (NSUInteger pageIndex = 0; pageIndex < [self numberOfPages]; pageIndex++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        
        CGRect buttonFrame = CGRectZero;
        buttonFrame.origin.x = originX;
        buttonFrame.origin.y = insetY;
        buttonFrame.size = (CGSize){ buttonSize, buttonSize };
        
        button.frame = buttonFrame;
        
        [button setTitle:@(pageIndex).stringValue forState:UIControlStateNormal];
        [button setTitleColor:_pageButtonNormalTitleColor forState:UIControlStateNormal];
        [button setTitleColor:_pageButtonSelectedTitleColor forState:UIControlStateSelected];
        [button setBackgroundColor:self.pageButtonNormalBackgroundColor];
        
        UILabel *titleLabel = button.titleLabel;
        titleLabel.font = [UIFont systemFontOfSize:12];
        
        button.tag = pageIndex;
        [button addTarget:self action:@selector(handleButtonTap:) forControlEvents:UIControlEventTouchUpInside];

        [_scrollView addSubview:button];
        
        originX = CGRectGetMaxX(button.frame) + insetX;
    }
    
    CGFloat contentWidth = 0.0;
    for (UIView *subview in _scrollView.subviews) {
        if ([subview isKindOfClass:UIButton.self]) {
            contentWidth = MAX(contentWidth, CGRectGetMaxX(subview.frame));
        }
    }
    contentWidth += insetX;
    
    _scrollView.contentSize = (CGSize){ contentWidth, self.bounds.size.height };
}

- (void)selectPageAtIndex:(NSInteger)pageIndex {
    UIButton *button = [self buttonForPageIndex:pageIndex];
    if (button) {
        [self handleButtonTap:button];
    }
}

- (void)handleButtonTap:(UIButton *)button {
    NSUInteger pageIndex = button.tag;
    
    if ([self.delegate respondsToSelector:@selector(pageBar:shouldSelectPageAtIndex:)]) {
        if (![self.delegate pageBar:self shouldSelectPageAtIndex:pageIndex]) {
            return;
        }
    }
    
    [self highlightButton:button atPageIndex:pageIndex];
    
    if ([self.delegate respondsToSelector:@selector(pageBar:didSelectPageAtIndex:)]) {
        [self.delegate pageBar:self didSelectPageAtIndex:pageIndex];
    }
}

- (nullable UIButton *)buttonForPageIndex:(NSInteger)pageIndex {
    for (UIView *subview in self.scrollView.subviews) {
        if ([subview isKindOfClass:UIButton.self] && subview.tag == pageIndex) {
            return (UIButton *)subview;
        }
    }
    return nil;
}

- (void)highlightButtonAtPageIndex:(NSInteger)pageIndex {
    UIButton *button = [self buttonForPageIndex:pageIndex];
    if (button) {
        [self highlightButton:button atPageIndex:pageIndex];
    }
}

- (void)highlightButton:(UIButton *)button atPageIndex:(NSInteger)pageIndex {
    // 熄灭所有按钮 (unhighlight all buttons)
    for (UIView *subview in _scrollView.subviews) {
        if ([subview isKindOfClass:UIButton.self]) {
            [self setButton:(UIButton *)subview selected:NO];
        }
    }
    
    // 点亮指定按钮 (highlight this button)
    [self setButton:button selected:YES];
    
    // 高亮按钮在屏幕上居中显示 (adjust contentOffset to center this button)
    CGRect visibleFrame = _scrollView.bounds;
    CGPoint contentOffset = visibleFrame.origin;
    CGFloat centerX = CGRectGetMidX(visibleFrame);
    if (![self isButtonCloseToScrollEdge:button]) {
        CGFloat distanceFromCenter = ABS(centerX - button.center.x);
        if (centerX < button.center.x) {
            contentOffset.x += distanceFromCenter;
        } else {
            contentOffset.x -= distanceFromCenter;
        }
        [_scrollView setContentOffset:contentOffset animated:YES];
    }
    // 将边缘被遮挡的高亮按钮显示在屏幕上 (or adjust contentOffset to fully display button which is closed to edges)
    else {
        // 左边缘 (for left edge)
        if (button.center.x < visibleFrame.size.width) {
            contentOffset.x = 0;
        }
        // 右边缘 (for right edge)
        else {
            contentOffset.x = _scrollView.contentSize.width - visibleFrame.size.width;
        }
        if (_scrollView.contentOffset.x != contentOffset.x) {
            [_scrollView setContentOffset:contentOffset animated:YES];
        }
    }
}

- (void)setButton:(UIButton *)button selected:(BOOL)selected {
    button.selected = selected;
    button.backgroundColor = selected ? self.pageButtonSelectedBackgroundColor : self.pageButtonNormalBackgroundColor;
}

#pragma mark * helper 

- (BOOL)isButtonCloseToScrollEdge:(UIButton *)button {
    CGSize contentSize = self.scrollView.contentSize;
    CGFloat halfWidth = self.scrollView.bounds.size.width / 2;
    CGFloat buttonCenterX = button.center.x;
    if (buttonCenterX < halfWidth || buttonCenterX > contentSize.width - halfWidth) {
        return YES;
    }
    return NO;
}

- (NSInteger)numberOfPages {
    return [_dataSource numberOfPagesInPageBar:self];
}

@end
