//
//  AFTImageScrollView.m
//  AFTPhotoScroller
//
//  Created by huangkun on 2017/1/15.
//  Copyright © 2017年 huangkun. All rights reserved.
//

#import "AFTImageScrollView.h"
#import "AFTPagingScrollView.h"

@interface AFTImageScrollView () <UIScrollViewDelegate>
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UITapGestureRecognizer *zoomingTap;
@end

@implementation AFTImageScrollView

- (id)initWithFrame:(CGRect)frame pagingScrollView:(AFTPagingScrollView *)pagingScrollView {
    self = [super initWithFrame:frame];
    if (self) {
        self.showsVerticalScrollIndicator = NO;
        self.showsHorizontalScrollIndicator = NO;
        self.bouncesZoom = YES;
        self.decelerationRate = UIScrollViewDecelerationRateFast;
        self.delegate = self;
        self.pagingScrollView = pagingScrollView;
    }
    return self;
}

- (instancetype)initWithPagingScrollView:(AFTPagingScrollView *)pagingScrollView {
    return [self initWithFrame:CGRectZero pagingScrollView:pagingScrollView];
}

#pragma mark - Override

- (void)layoutSubviews {
    [super layoutSubviews];
    [self centerImage];
}

#pragma mark - UIScrollViewDeletate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return _imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self centerImage];
    [self resetScrollEnabled];
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    [self resetScrollEnabled];
    
    if ([_pagingScrollView.delegate respondsToSelector:@selector(pagingScrollView:imageScrollViewWillBeginZooming:atPageIndex:)]) {
        [_pagingScrollView.delegate pagingScrollView:_pagingScrollView imageScrollViewWillBeginZooming:self atPageIndex:_pageIndex];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([_pagingScrollView.delegate respondsToSelector:@selector(pagingScrollView:imageScrollViewDidScrollImage:atPageIndex:)]) {
        [_pagingScrollView.delegate pagingScrollView:_pagingScrollView imageScrollViewDidScrollImage:self atPageIndex:_pageIndex];
    }
}

#pragma mark - Configure scrollView to display new image (tiled or not)

- (void)displayImage:(UIImage *)image {
    // turn off scroll enabled
    self.scrollEnabled = NO;
    
    // clear the previous imageView
    [_imageView removeFromSuperview];
    _imageView = nil;
    
    // reset our zoomScale to 1.0 before doing any further calculations
    self.zoomScale = 1.0;
    
    // make a new UIImageView for the new image
    _imageView = [[UIImageView alloc] initWithImage:image];
    [self addSubview:_imageView];
    
    self.contentSize = [image size];
    [self setMaxMinZoomScalesForCurrentBounds];
    self.zoomScale = self.minimumZoomScale;
    
    // zoom tap
    if (_pagingScrollView.zoomingTapEnabled) {
        [_imageView addGestureRecognizer:self.zoomingTap];
        _imageView.userInteractionEnabled = YES;
    }
}

- (void)setMaxMinZoomScalesForCurrentBounds {
    CGSize boundsSize = self.bounds.size;
    CGSize imageSize = _imageView.bounds.size;
    
    // calculate min/max zoomscale
    CGFloat xScale = boundsSize.width / imageSize.width;    // the scale needed to perfectly fit the image width-wise
    CGFloat yScale = boundsSize.height / imageSize.height;  // the scale needed to perfectly fit the image height-wise
    CGFloat minScale = MIN(xScale, yScale);                 // use minimum of these to allow the image to become fully visible
    
    self.maximumZoomScale = MAX(_pagingScrollView.maximumImageZoomScale, minScale);
    self.minimumZoomScale = minScale;
}

- (void)zoomToCenter:(CGPoint)center animated:(BOOL)animated {
    CGFloat currentScale = self.zoomScale;
    CGFloat minScale = self.minimumZoomScale;
    CGFloat maxScale = self.maximumZoomScale;
    
    if (minScale == maxScale && minScale > 1) {
        return;
    }
    
    CGFloat progress = _pagingScrollView.zoomingTapProgress;
    CGFloat toScale = maxScale * progress;
    CGFloat finalScale = (currentScale == minScale) ? toScale : minScale;
    
    CGRect zoomRect = [self zoomRectForScale:finalScale withCenter:center];
    [self zoomToRect:zoomRect animated:animated];
}

#pragma mark - Methods called during rotation to preserve the zoomScale and the visible portion of the image

// returns the center point, in image coordinate space, to try to restore after rotation.
- (CGPoint)pointToCenterAfterRotation {
    CGPoint boundsCenter = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    return [self convertPoint:boundsCenter toView:_imageView];
}

// returns the zoom scale to attempt to restore after rotation.
- (CGFloat)scaleToRestoreAfterRotation {
    CGFloat contentScale = self.zoomScale;
    
    // If we're at the minimum zoom scale, preserve that by returning 0, which will be converted to the minimum
    // allowable scale when the scale is restored.
    if (contentScale <= self.minimumZoomScale + FLT_EPSILON) {
        contentScale = 0;
    }
    
    return contentScale;
}

- (CGPoint)maximumContentOffset {
    CGSize contentSize = self.contentSize;
    CGSize boundsSize = self.bounds.size;
    return CGPointMake(contentSize.width - boundsSize.width, contentSize.height - boundsSize.height);
}

- (CGPoint)minimumContentOffset {
    return CGPointZero;
}

// Adjusts content offset and scale to try to preserve the old zoomscale and center.
- (void)restoreCenterPoint:(CGPoint)oldCenter scale:(CGFloat)oldScale {
    // Step 1: restore zoom scale, first making sure it is within the allowable range.
    self.zoomScale = MIN(self.maximumZoomScale, MAX(self.minimumZoomScale, oldScale));
    
    // Step 2: restore center point, first making sure it is within the allowable range.
    
    // 2a: convert our desired center point back to our own coordinate space
    CGPoint boundsCenter = [self convertPoint:oldCenter fromView:_imageView];
    // 2b: calculate the content offset that would yield that center point
    CGPoint offset = CGPointMake(boundsCenter.x - self.bounds.size.width / 2.0,
                                 boundsCenter.y - self.bounds.size.height / 2.0);
    // 2c: restore offset, adjusted to be within the allowable range
    CGPoint maxOffset = [self maximumContentOffset];
    CGPoint minOffset = [self minimumContentOffset];
    offset.x = MAX(minOffset.x, MIN(maxOffset.x, offset.x));
    offset.y = MAX(minOffset.y, MIN(maxOffset.y, offset.y));
    self.contentOffset = offset;
}

#pragma mark - Helper

- (void)centerImage {
    // center the image as it becomes smaller than the size of the screen
    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = _imageView.frame;
    
    // center horizontally
    if (frameToCenter.size.width < boundsSize.width) {
        frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
    } else {
        frameToCenter.origin.x = 0;
    }
    
    // center vertically
    if (frameToCenter.size.height < boundsSize.height) {
        frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
    } else {
        frameToCenter.origin.y = 0;
    }
    
    _imageView.frame = frameToCenter;
}

- (void)resetScrollEnabled {
    self.scrollEnabled = (self.zoomScale > self.minimumZoomScale);
}

#pragma mark - Zoom tap

- (UITapGestureRecognizer *)zoomingTap {
    if (!_zoomingTap) {
        _zoomingTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleZoomingTap:)];
        _zoomingTap.numberOfTapsRequired = 2;
        
        if ([_pagingScrollView.delegate respondsToSelector:@selector(pagingScrollView:imageScrollView:didEnableZoomingTapGesture:)]) {
            [_pagingScrollView.delegate pagingScrollView:_pagingScrollView imageScrollView:self didEnableZoomingTapGesture:_zoomingTap];
        }
    }
    return _zoomingTap;
}

- (void)handleZoomingTap:(UITapGestureRecognizer *)tap {
    if ([_pagingScrollView.delegate respondsToSelector:@selector(pagingScrollView:imageScrollView:didRecognizeZoomingTapGesture:)]) {
        [_pagingScrollView.delegate pagingScrollView:_pagingScrollView imageScrollView:self didRecognizeZoomingTapGesture:tap];
    }
    
    CGPoint location = [tap locationInView:tap.view];
    [self zoomToCenter:location animated:YES];
}

// The center should be in the imageView's coordinates
- (CGRect)zoomRectForScale:(CGFloat)scale withCenter:(CGPoint)center {
    CGRect zoomRect;
    CGRect bounds = self.bounds;
    
    // the zoom rect is in the content view's coordinates.
    //At a zoom scale of 1.0, it would be the size of the imageScrollView's bounds.
    //As the zoom scale decreases, so more content is visible, the size of the rect grows.
    zoomRect.size.width = bounds.size.width / scale;
    zoomRect.size.height = bounds.size.height / scale;
    
    // choose an origin so as to get the right center.
    zoomRect.origin.x = center.x - (zoomRect.size.width / 2.0);
    zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0);
    
    return zoomRect;
}

@end
