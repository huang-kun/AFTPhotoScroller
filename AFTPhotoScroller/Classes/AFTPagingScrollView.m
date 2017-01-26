//
//  AFTPagingScrollView.m
//  AFTPhotoScroller
//
//  Created by huangkun on 2017/1/15.
//  Copyright © 2017年 huangkun. All rights reserved.
//

#import "AFTPagingScrollView.h"
#import "AFTImageScrollView.h"

#define AFT_PAGING_DEBUG 0
#define AFT_PAGING_IMAGE_CACHE_LOG 0

@interface AFTPagingScrollView () <UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *pagingScrollView;
@property (nonatomic, strong) UIView *parallaxSeparatorView;

@property (nonatomic, strong) NSMutableSet *recycledPages;
@property (nonatomic, strong) NSMutableSet *visiblePages;

@property (nonatomic, assign) NSInteger currentPageIndex;
@property (nonatomic, assign) NSInteger nextPageIndex;

@property (nonatomic, strong) NSMutableDictionary <NSNumber *, UIImage *> *imageCache; // It only caches 3 images for increasing the dragging behavior between pages back and forth.

@end


@implementation AFTPagingScrollView {
    
    NSInteger _pageCount;           // numberOfPages
    
    CGFloat _pagePadding;           // paddingBetweenPages
    CGFloat _parallaxPagePadding;
    
    CGPoint _lastContentOffset;
    BOOL _firstTimeLoadPage;
    
    NSInteger _firstVisiblePageIndexBeforeRotation;
    CGFloat _percentScrolledIntoFirstVisiblePage;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.backgroundColor = [UIColor blackColor];
    
    _recycledPages = [[NSMutableSet alloc] init];
    _visiblePages  = [[NSMutableSet alloc] init];
    _imageCache = [[NSMutableDictionary alloc] init];
    
    _firstTimeLoadPage = YES;
    _lastContentOffset = CGPointZero;
    
    _maximumImageZoomScale = 1.0;
    _zoomingTapEnabled = YES;
    _zoomingTapProgress = 1.0;
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(removeImageCache)
                                               name:UIApplicationDidReceiveMemoryWarningNotification
                                             object:UIApplication.sharedApplication];
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:UIApplicationDidReceiveMemoryWarningNotification
                                                object:UIApplication.sharedApplication];
}

#pragma mark - Accessors

- (NSInteger)numberOfPages {
    return _pageCount;
}

- (CGFloat)paddingBetweenPages {
    return _parallaxScrollingEnabled ? _parallaxPagePadding : _pagePadding;
}

- (void)setZoomingTapProgress:(CGFloat)zoomingTapProgress {
    if (zoomingTapProgress > 1) zoomingTapProgress = 1;
    if (zoomingTapProgress <= 0) zoomingTapProgress = 1;
    _zoomingTapProgress = zoomingTapProgress;
}

- (void)setCurrentPageIndex:(NSInteger)currentPageIndex {
    [self setCurrentPageIndex:currentPageIndex byPagingScroll:NO];
}

- (void)setCurrentPageIndex:(NSInteger)currentPageIndex byPagingScroll:(BOOL)scroll {
    if (_firstTimeLoadPage || _currentPageIndex != currentPageIndex) {
        _firstTimeLoadPage = NO;
        _currentPageIndex = currentPageIndex;
        
        if (scroll) {
            if ([_delegate respondsToSelector:@selector(pagingScrollView:didScrollToPageAtIndex:)]) {
                [_delegate pagingScrollView:self didScrollToPageAtIndex:currentPageIndex];
            }
        }
    }
}

- (void)setNextPageIndex:(NSInteger)nextPageIndex {
    if (_nextPageIndex != nextPageIndex) {
        _nextPageIndex = nextPageIndex;
    }
}

#pragma mark - Reload data and build user interface

- (void)reloadPageAtIndex:(NSInteger)pageIndex {
    for (AFTImageScrollView *page in _visiblePages) {
        if (page.pageIndex == pageIndex) {
            _imageCache[@(pageIndex)] = nil;
            [self configurePage:page forIndex:pageIndex];
            break;
        }
    }
}

- (void)reloadData {
    // reset states
    _pageCount = 0;
    _pagePadding = 0;
    _parallaxPagePadding = 20;
    
    // apply new values
    _pageCount = [_dataSource numberOfPagesInPagingScrollView:self];
    
    if (_pageCount < 0) {
        _pageCount = 0;
    }
    
    if ([_delegate respondsToSelector:@selector(paddingBetweenPagesInPagingScrollView:)]) {
        CGFloat padding = [_delegate paddingBetweenPagesInPagingScrollView:self];
        
        if (padding < 0) {
            padding = 0;
        }
        
        if (_parallaxScrollingEnabled) {
            _parallaxPagePadding = padding;
        } else {
            _pagePadding = padding;
        }
    }
    
    for (UIView *subview in self.subviews) {
        [subview removeFromSuperview];
    }
    
    [self buildInterface];
}

- (void)buildInterface {
    // Build paging scroll view
    CGRect pagingScrollViewFrame = [self frameForPagingScrollView];
    
    _pagingScrollView = [[UIScrollView alloc] initWithFrame:pagingScrollViewFrame];
    _pagingScrollView.backgroundColor = [UIColor blackColor];
    _pagingScrollView.pagingEnabled = YES;
    _pagingScrollView.showsVerticalScrollIndicator = NO;
    _pagingScrollView.showsHorizontalScrollIndicator = NO;
    _pagingScrollView.bounces = YES;
    _pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
    _pagingScrollView.delegate = self;
    
    if ([self isHorizontalDirection]) {
        _pagingScrollView.alwaysBounceVertical = NO;
        _pagingScrollView.alwaysBounceHorizontal = YES;
    } else {
        _pagingScrollView.alwaysBounceVertical = YES;
        _pagingScrollView.alwaysBounceHorizontal = NO;
    }
    
    [self addSubview:_pagingScrollView];
    
    // Build parallax separator if necessary
    if (_parallaxScrollingEnabled) {
        CGRect parallaxSeparatorFrame = _pagingScrollView.bounds;
        
        if ([self isHorizontalDirection]) {
            parallaxSeparatorFrame.size.width = _parallaxPagePadding * 2;
        } else {
            parallaxSeparatorFrame.size.height = _parallaxPagePadding * 2;
        }
        
        _parallaxSeparatorView = [[UIView alloc] initWithFrame:parallaxSeparatorFrame];
        _parallaxSeparatorView.backgroundColor = _pagingScrollView.backgroundColor;
        
        [_pagingScrollView addSubview:_parallaxSeparatorView];
        
#if AFT_PAGING_DEBUG
        _parallaxSeparatorView.backgroundColor = UIColor.redColor;
        _parallaxSeparatorView.alpha = 0.5;
#endif
        
    }
    
    // Display first page
    [self tilePages];
}

#pragma mark - Tiling and page configuration

- (void)tilePages {
    // Calculate which pages are visible
    CGRect visibleBounds = _pagingScrollView.bounds;
    CGFloat pageWidth = visibleBounds.size.width;
    CGFloat pageHeight = visibleBounds.size.height;
    
    NSInteger firstNeededPageIndex = 0;
    NSInteger lastNeededPageIndex  = 0;
    
    if ([self isHorizontalDirection]) {
        firstNeededPageIndex = floorf(CGRectGetMinX(visibleBounds) / pageWidth);
        lastNeededPageIndex  = floorf((CGRectGetMaxX(visibleBounds)-1) / pageWidth);
    } else {
        firstNeededPageIndex = floorf(CGRectGetMinY(visibleBounds) / pageHeight);
        lastNeededPageIndex  = floorf((CGRectGetMaxY(visibleBounds)-1) / pageHeight);
    }
    
    firstNeededPageIndex = MAX(firstNeededPageIndex, 0);
    lastNeededPageIndex = MIN(lastNeededPageIndex, _pageCount - 1);
    
    CGPoint contentOffset = visibleBounds.origin;
    CGFloat centerOffsetX = contentOffset.x + pageWidth / 2;
    CGFloat centerOffsetY = contentOffset.y + pageHeight / 2;
    
    NSInteger currentPageIndex = firstNeededPageIndex;
    NSInteger nextPageIndex = firstNeededPageIndex;
    
    if ([self isHorizontalDirection]) {
        CGFloat lastPageStartX = lastNeededPageIndex * pageWidth;
        
        if (lastPageStartX <= centerOffsetX) {
            currentPageIndex = lastNeededPageIndex;
        }
        
        if (_lastContentOffset.x > contentOffset.x) {
            nextPageIndex = MIN(firstNeededPageIndex, lastNeededPageIndex);
        } else if (_lastContentOffset.x < contentOffset.x) {
            nextPageIndex = MAX(firstNeededPageIndex, lastNeededPageIndex);
        }
    } else {
        CGFloat lastPageStartY = lastNeededPageIndex * pageHeight;
        
        if (lastPageStartY <= centerOffsetY) {
            currentPageIndex = lastNeededPageIndex;
        }
        
        if (_lastContentOffset.y > contentOffset.y) {
            nextPageIndex = MIN(firstNeededPageIndex, lastNeededPageIndex);
        } else if (_lastContentOffset.y < contentOffset.y) {
            nextPageIndex = MAX(firstNeededPageIndex, lastNeededPageIndex);
        }
    }
    
    _lastContentOffset = contentOffset;

    
    // Should continue
    if ([_delegate respondsToSelector:@selector(pagingScrollView:shouldDisplayPageAtIndex:)]) {
        if ([_delegate pagingScrollView:self shouldDisplayPageAtIndex:nextPageIndex]) {
            [self setNextPageIndex:nextPageIndex];
        } else {
            // reset paging offset
            CGPoint offset = [self contentOffsetForPagingEnabledAtPageIndex:_currentPageIndex];
            [_pagingScrollView setContentOffset:offset animated:NO];
            return;
        }
    }
    
    // Recycle no-longer-visible pages
    for (AFTImageScrollView *page in _visiblePages) {
        if (page.pageIndex < firstNeededPageIndex || page.pageIndex > lastNeededPageIndex) {
            [_recycledPages addObject:page];
            [page removeFromSuperview];
            
            if ([_delegate respondsToSelector:@selector(pagingScrollView:imageScrollView:didRecycleForPageIndex:)]) {
                [_delegate pagingScrollView:self imageScrollView:page didRecycleForPageIndex:page.pageIndex];
            }
        }
    }
    [_visiblePages minusSet:_recycledPages];
    
    // Add missing pages
    for (NSInteger index = firstNeededPageIndex; index <= lastNeededPageIndex; index++) {
        if (![self isDisplayingPageForIndex:index]) {
            AFTImageScrollView *page = [self dequeueRecycledPage];
            if (page == nil) {
                page = [[AFTImageScrollView alloc] initWithPagingScrollView:self];
            }
            [self configurePage:page forIndex:index];
            [_pagingScrollView addSubview:page];
            [_visiblePages addObject:page];
            
            if ([_delegate respondsToSelector:@selector(pagingScrollView:imageScrollView:didReuseForPageIndex:)]) {
                [_delegate pagingScrollView:self imageScrollView:page didReuseForPageIndex:page.pageIndex];
            }
            
            if (_parallaxScrollingEnabled) {
                [_pagingScrollView bringSubviewToFront:_parallaxSeparatorView];
            }
        }
    }

    [self setCurrentPageIndex:currentPageIndex byPagingScroll:YES];
    
    // Apply parallax scrolling if necessary
    if (_parallaxScrollingEnabled) {
        [self applyParallaxScrollingEffect];
    }
}

- (void)displayPageAtIndex:(NSInteger)index {
    if (index >= _pageCount) {
        return;
    }
    
    if ([_delegate respondsToSelector:@selector(pagingScrollView:shouldDisplayPageAtIndex:)]) {
        if ([_delegate pagingScrollView:self shouldDisplayPageAtIndex:index]) {
            [self setNextPageIndex:index];
        } else {
            return;
        }
    }
    
    // Recycle no-longer-visible pages
    for (AFTImageScrollView *page in _visiblePages) {
        if (page.pageIndex != index) {
            [_recycledPages addObject:page];
            [page removeFromSuperview];
            
            if ([_delegate respondsToSelector:@selector(pagingScrollView:imageScrollView:didRecycleForPageIndex:)]) {
                [_delegate pagingScrollView:self imageScrollView:page didRecycleForPageIndex:page.pageIndex];
            }
        }
    }
    [_visiblePages minusSet:_recycledPages];
    
    // Add missing pages
    if (![self isDisplayingPageForIndex:index]) {
        AFTImageScrollView *page = [self dequeueRecycledPage];
        if (page == nil) {
            page = [[AFTImageScrollView alloc] initWithPagingScrollView:self];
        }
        [self configurePage:page forIndex:index];
        [_pagingScrollView addSubview:page];
        [_visiblePages addObject:page];
        
        // Jump to specified page without calling -scrollViewDidScroll: method
        CGRect pagingBounds = _pagingScrollView.bounds;
        pagingBounds.origin.x = page.frame.origin.x - _pagePadding;
        _pagingScrollView.bounds = pagingBounds;
        
        if ([_delegate respondsToSelector:@selector(pagingScrollView:imageScrollView:didReuseForPageIndex:)]) {
            [_delegate pagingScrollView:self imageScrollView:page didReuseForPageIndex:page.pageIndex];
        }
    }
    
    [self setCurrentPageIndex:index];
    
    if ([_delegate respondsToSelector:@selector(pagingScrollView:didDisplayPageAtIndex:)]) {
        [_delegate pagingScrollView:self didDisplayPageAtIndex:index];
    }
    
    [self updateImageCache];
}

- (AFTImageScrollView *)dequeueRecycledPage {
    AFTImageScrollView *page = [_recycledPages anyObject];
    if (page) {
        [_recycledPages removeObject:page];
    }
    return page;
}

- (BOOL)isDisplayingPageForIndex:(NSInteger)index {
    BOOL foundPage = NO;
    for (AFTImageScrollView *page in _visiblePages) {
        if (page.pageIndex == index) {
            foundPage = YES;
            break;
        }
    }
    return foundPage;
}

- (void)configurePage:(AFTImageScrollView *)page forIndex:(NSInteger)index {
    page.pageIndex = index;
    page.frame = [self frameForPageAtIndex:index];
    
    UIImage *image = _imageCache[@(index)];
    if (!image) {
        image = [_dataSource pagingScrollView:self imageForPageAtIndex:index];
        _imageCache[@(index)] = image;
    }
    [page displayImage:image];
    
#if AFT_PAGING_DEBUG
    page.backgroundColor = UIColor.lightGrayColor;
#endif
    
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self tilePages];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if ([_delegate respondsToSelector:@selector(pagingScrollViewWillBeginPaging:)]) {
        [_delegate pagingScrollViewWillBeginPaging:self];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if ([_delegate respondsToSelector:@selector(pagingScrollView:didDisplayPageAtIndex:)]) {
        [_delegate pagingScrollView:self didDisplayPageAtIndex:_currentPageIndex];
    }
    [self updateImageCache];
}

#pragma mark - Calculations

- (CGRect)frameForPagingScrollView {
    CGFloat padding = _pagePadding;
    CGRect frame = [self bounds];
    
    if ([self isHorizontalDirection]) {
        frame.origin.x -= padding;
        frame.size.width += (padding * 2);
    } else {
        frame.origin.y -= padding;
        frame.size.height += (padding * 2);
    }
    
    return frame;
}

- (CGRect)frameForPageAtIndex:(NSInteger)index {
    CGFloat padding = _pagePadding;
    CGRect bounds = _pagingScrollView.bounds;
    CGRect pageFrame = bounds;
    
    if ([self isHorizontalDirection]) {
        pageFrame.size.width -= (padding * 2);
        pageFrame.origin.x = (bounds.size.width * index) + padding;
    } else {
        pageFrame.size.height -= (padding * 2);
        pageFrame.origin.y = (bounds.size.height * index) + padding;
    }
    
    return pageFrame;
}

- (CGSize)contentSizeForPagingScrollView {
    CGRect bounds = _pagingScrollView.bounds;
    CGSize size = CGSizeZero;
    
    if ([self isHorizontalDirection]) {
        size.width = bounds.size.width * _pageCount;
    } else {
        size.height = bounds.size.height * _pageCount;
    }
    
    return size;
}

- (CGPoint)contentOffsetForPagingEnabledAtPageIndex:(NSInteger)pageIndex {
    CGRect bounds = _pagingScrollView.bounds;
    
    if ([self isHorizontalDirection]) {
        CGFloat pageWidth = bounds.size.width;
        CGFloat offsetX = pageIndex * pageWidth;
        bounds.origin.x = offsetX;
    } else {
        CGFloat pageHeight = bounds.size.height;
        CGFloat offsetY = pageIndex * pageHeight;
        bounds.origin.y = offsetY;
    }
    
    return bounds.origin;
}

// Not used here.
- (CGPoint)contentOffsetFromTargetContentOffset:(CGPoint)contentOffset {
    CGFloat pageWidth = _pagingScrollView.bounds.size.width;
    CGFloat overshoot = fmodf(contentOffset.x, pageWidth);
    if (overshoot < pageWidth / 2) {
        contentOffset.x -= overshoot;
    } else {
        contentOffset.x += (pageWidth - overshoot);
    }
    return contentOffset;
}

#pragma mark - Helper

- (BOOL)isHorizontalDirection {
    return _navigationOrientation == AFTPagingScrollViewNavigationOrientationHorizontal;
}

- (BOOL)isVerticalDirection {
    return _navigationOrientation == AFTPagingScrollViewNavigationOrientationVertical;
}

#pragma mark - Image Cache

- (void)updateImageCache {
    NSInteger currentPage = _currentPageIndex;
    NSInteger numberOfPages = _pageCount;

    for (NSInteger page = 0; page < numberOfPages; page++) {
        NSNumber *pageKey = @(page);
        BOOL shouldCache = (page == currentPage || page == currentPage - 1 || page == currentPage + 1);
        
        // remove cached image
        if (!shouldCache && _imageCache[pageKey]) {
            _imageCache[pageKey] = nil;
        }
        
        // cache new image
        else if (shouldCache && !_imageCache[pageKey]) {
            UIImage *image = [_dataSource pagingScrollView:self imageForPageAtIndex:page];
            _imageCache[pageKey] = image;
        }
    }
    
#if AFT_PAGING_IMAGE_CACHE_LOG
    
    NSMutableString *desc = [NSMutableString stringWithFormat:@"[%@] image cache indexes: ", NSStringFromClass(self.class)];
    NSArray *allKeys = [_imageCache.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSNumber *obj1, NSNumber *obj2) {
        return obj1 > obj2;
    }];
    
    for (NSNumber *cachedKey in allKeys) {
        [desc appendFormat:@"%@, ", cachedKey.stringValue];
    }
    
    NSLog(@"%@", desc);
    
#endif
    
}

- (void)removeImageCache {
    [_imageCache removeAllObjects];
}

#pragma mark - Parallax Scrolling

- (void)applyParallaxScrollingEffect {
    CGRect bounds = _pagingScrollView.bounds;
    CGRect parallaxSeparatorFrame = _parallaxSeparatorView.frame;

    CGPoint offset = bounds.origin;
    CGFloat pageWidth = bounds.size.width;
    CGFloat pageHeight = bounds.size.height;

    if ([self isHorizontalDirection]) {
        NSInteger firstPageIndex = floorf(CGRectGetMinX(bounds) / pageWidth);
        
        CGFloat x = offset.x - pageWidth * firstPageIndex;
        CGFloat percentage = x / pageWidth;
        
        parallaxSeparatorFrame.origin.x = pageWidth * (firstPageIndex + 1) - parallaxSeparatorFrame.size.width * percentage;
    } else {
        NSInteger firstPageIndex = floorf(CGRectGetMinY(bounds) / pageHeight);
        
        CGFloat y = offset.y - pageHeight * firstPageIndex;
        CGFloat percentage = y / pageHeight;
        
        parallaxSeparatorFrame.origin.y = pageHeight * (firstPageIndex + 1) - parallaxSeparatorFrame.size.height * percentage;
    }
    
    _parallaxSeparatorView.frame = parallaxSeparatorFrame;
}

#pragma mark - Rotation

- (void)saveCurrentStatesForRotation {
    CGFloat offset = _pagingScrollView.contentOffset.x;
    CGFloat pageWidth = _pagingScrollView.bounds.size.width;
    
    if (offset >= 0) {
        _firstVisiblePageIndexBeforeRotation = floorf(offset / pageWidth);
        _percentScrolledIntoFirstVisiblePage = (offset - (_firstVisiblePageIndexBeforeRotation * pageWidth)) / pageWidth;
    } else {
        _firstVisiblePageIndexBeforeRotation = 0;
        _percentScrolledIntoFirstVisiblePage = offset / pageWidth;
    }
}

- (void)restoreStatesForRotation {
    // recalculate contentSize based on current orientation
    CGRect pagingScrollViewFrame = [self frameForPagingScrollView];
    _pagingScrollView.frame = pagingScrollViewFrame;
    _pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
    
    // adjust frames and configuration of each visible page
    for (AFTImageScrollView *page in _visiblePages) {
        CGPoint restorePoint = [page pointToCenterAfterRotation];
        CGFloat restoreScale = [page scaleToRestoreAfterRotation];
        page.frame = [self frameForPageAtIndex:page.pageIndex];
        [page setMaxMinZoomScalesForCurrentBounds];
        [page restoreCenterPoint:restorePoint scale:restoreScale];
    }
    
    // adjust contentOffset to preserve page location based on values collected prior to location
    CGFloat pageWidth = _pagingScrollView.bounds.size.width;
    CGFloat newOffset = (_firstVisiblePageIndexBeforeRotation * pageWidth) + (_percentScrolledIntoFirstVisiblePage * pageWidth);
    _pagingScrollView.contentOffset = CGPointMake(newOffset, 0);
}

- (void)restoreStatesForRotationInSize:(CGSize)size {
    CGRect bounds = self.bounds;
    if (bounds.size.width != size.width || bounds.size.height != size.height) {
        bounds.size.width = size.width;
        bounds.size.height = size.height;
        
        self.bounds = bounds;
        _pagingScrollView.bounds = bounds;
        
        [self restoreStatesForRotation];
    }
}

@end
