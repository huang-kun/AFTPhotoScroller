//
//  AFTImageScrollView.h
//  AFTPhotoScroller
//
//  Created by huangkun on 2017/1/15.
//  Copyright © 2017年 huangkun. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AFTPagingScrollView;

@interface AFTImageScrollView : UIScrollView

- (instancetype)initWithPagingScrollView:(AFTPagingScrollView *)pagingScrollView;

@property (nonatomic, assign) NSInteger pageIndex;
@property (nonatomic, weak) AFTPagingScrollView *pagingScrollView;

- (void)displayImage:(UIImage *)image;
- (void)setMaxMinZoomScalesForCurrentBounds;

- (CGPoint)pointToCenterAfterRotation;
- (CGFloat)scaleToRestoreAfterRotation;
- (void)restoreCenterPoint:(CGPoint)oldCenter scale:(CGFloat)oldScale;

@end
