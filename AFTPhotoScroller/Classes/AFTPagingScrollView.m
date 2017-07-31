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

void *kAFTPagingScrollViewKVOContext = &kAFTPagingScrollViewKVOContext;


@interface AFTPagingScrollView () <UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *pagingScrollView;
@property (nonatomic, strong) UIView *parallaxSeparator;

@property (nonatomic, strong) NSMutableSet <AFTImageScrollView *> *recycledPages;
@property (nonatomic, strong) NSMutableSet <AFTImageScrollView *> *visiblePages;

@property (nonatomic, assign) NSInteger currentPageIndex;
@property (nonatomic, assign) NSInteger nextPageIndex;

@property (nonatomic, strong) NSMutableDictionary <NSNumber *, UIImage *> *imageCache; // It only caches 3 images for increasing the dragging behavior between pages back and forth.

@end


@implementation AFTPagingScrollView {
    
    NSInteger _pageCount;
    
    CGFloat _pagePadding;
    CGFloat _parallaxPagePadding;
    
    CGPoint _lastContentOffset;
    BOOL _firstTimeLoadPage;
    
    NSInteger _firstVisiblePageIndexBeforeRotation;
    CGFloat _percentScrolledIntoFirstVisiblePage;
    
}

#pragma mark - Life cycle

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
    
    [self addObserver:self
           forKeyPath:@"backgroundColor"
              options:NSKeyValueObservingOptionNew
              context:kAFTPagingScrollViewKVOContext];
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:UIApplicationDidReceiveMemoryWarningNotification
                                                object:UIApplication.sharedApplication];
    
    [self removeObserver:self
              forKeyPath:@"backgroundColor"
                 context:kAFTPagingScrollViewKVOContext];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // Fix bugs for loading from interface builder (UIStoryboard)
    // ----------------------------------------------------------
    if (_parallaxScrollingEnabled) {
        CGRect parallaxSeparatorFrame = _parallaxSeparator.frame;
        parallaxSeparatorFrame.size = [self sizeForParallaxSeparator];
        _parallaxSeparator.frame = parallaxSeparatorFrame;
    }
    [self saveCurrentStatesForRotation];
    [self restoreStatesForRotation];
    // ----------------------------------------------------------
}

#pragma mark - Accessors

- (NSInteger)numberOfPages {
    return _pageCount;
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

- (void)setPaddingBetweenPages:(CGFloat)paddingBetweenPages {
    _pagePadding = paddingBetweenPages;
}

- (CGFloat)paddingBetweenPages {
    return _parallaxScrollingEnabled ? _parallaxPagePadding : _pagePadding;
}

#pragma mark - Reload data and build user interface

- (void)reloadPageAtIndex:(NSInteger)pageIndex {
    _imageCache[@(pageIndex)] = nil;
    for (AFTImageScrollView *page in _visiblePages) {
        if (page.pageIndex == pageIndex) {
            [self configurePage:page forIndex:pageIndex];
            break;
        }
    }
}

- (void)reloadData {
    // page count
    _pageCount = 0;
    _pageCount = [_dataSource numberOfPagesInPagingScrollView:self];
    
    if (_pageCount < 0) {
        _pageCount = 0;
    }
    
    // page padding
    if (_pagePadding < 0) {
        _pagePadding = 0;
    }
    
    if (_parallaxScrollingEnabled) {
        _parallaxPagePadding = _pagePadding > 0 ? _pagePadding : 20;
        _pagePadding = 0;
    }
    
    // build interface
    for (UIView *subview in self.subviews) {
        [subview removeFromSuperview];
    }
    
    [self buildInterface];
}

- (void)buildInterface {
    // Build paging scroll view
    CGRect pagingScrollViewFrame = [self frameForPagingScrollView];
    
    _pagingScrollView = [[UIScrollView alloc] initWithFrame:pagingScrollViewFrame];
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
        CGRect parallaxSeparatorFrame = CGRectZero;
        parallaxSeparatorFrame.size = [self sizeForParallaxSeparator];
        
        _parallaxSeparator = [[UIView alloc] initWithFrame:parallaxSeparatorFrame];
        [_pagingScrollView addSubview:_parallaxSeparator];
        
#if AFT_PAGING_DEBUG
        _parallaxSeparator.backgroundColor = UIColor.redColor;
        _parallaxSeparator.alpha = 0.5;
#endif
        
    }
    
    // Update background color
    [self updateBackgroundColor:self.backgroundColor];
    
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
                [_pagingScrollView bringSubviewToFront:_parallaxSeparator];
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
        
        if ([self isHorizontalDirection]) {
            pagingBounds.origin.x = page.frame.origin.x - _pagePadding;
        } else {
            pagingBounds.origin.y = page.frame.origin.y - _pagePadding;
        }
        
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
    page.backgroundColor = self.backgroundColor;
    
    UIImage *image = _imageCache[@(index)];
    if (!image) {
        image = [_dataSource pagingScrollView:self imageForPageAtIndex:index];
        _imageCache[@(index)] = image;
    }
    [page displayImage:image];
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

- (CGSize)sizeForParallaxSeparator {
    CGSize parallaxSeparatorSize = CGSizeZero;
    CGSize pagingSize = [self frameForPagingScrollView].size;

    if ([self isHorizontalDirection]) {
        parallaxSeparatorSize.width = _parallaxPagePadding * 2;
        parallaxSeparatorSize.height = MAX(pagingSize.width, pagingSize.height);
    } else {
        parallaxSeparatorSize.height = _parallaxPagePadding * 2;
        parallaxSeparatorSize.width = MAX(pagingSize.width, pagingSize.height);
    }
    
    return parallaxSeparatorSize;
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

- (void)updateBackgroundColor:(UIColor *)color {
    _pagingScrollView.backgroundColor = color;
    _parallaxSeparator.backgroundColor = color;
    
    for (AFTImageScrollView *page in _visiblePages) {
        page.backgroundColor = color;
    }
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
    CGRect parallaxSeparatorFrame = _parallaxSeparator.frame;

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
    
    _parallaxSeparator.frame = parallaxSeparatorFrame;
}

#pragma mark - Rotation

- (void)saveCurrentStatesForRotation {
    CGFloat offset = 0;
    CGFloat pageLength = 0;
    
    if ([self isHorizontalDirection]) {
        offset = _pagingScrollView.contentOffset.x;
        pageLength = _pagingScrollView.bounds.size.width;
    } else {
        offset = _pagingScrollView.contentOffset.y;
        pageLength = _pagingScrollView.bounds.size.height;
    }
    
    if (offset >= 0) {
        _firstVisiblePageIndexBeforeRotation = floorf(offset / pageLength);
        _percentScrolledIntoFirstVisiblePage = (offset - (_firstVisiblePageIndexBeforeRotation * pageLength)) / pageLength;
    } else {
        _firstVisiblePageIndexBeforeRotation = 0;
        _percentScrolledIntoFirstVisiblePage = offset / pageLength;
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
    CGPoint contentOffset = CGPointZero;
    
    if ([self isHorizontalDirection]) {
        CGFloat pageWidth = _pagingScrollView.bounds.size.width;
        contentOffset.x = (_firstVisiblePageIndexBeforeRotation * pageWidth) + (_percentScrolledIntoFirstVisiblePage * pageWidth);
    } else {
        CGFloat pageHeight = _pagingScrollView.bounds.size.height;
        contentOffset.y = (_firstVisiblePageIndexBeforeRotation * pageHeight) + (_percentScrolledIntoFirstVisiblePage * pageHeight);
    }
    
    _pagingScrollView.contentOffset = contentOffset;
    
    // adjust position for parallax bar
    if (_parallaxScrollingEnabled) {
        [self applyParallaxScrollingEffect];
    }
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

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (context == kAFTPagingScrollViewKVOContext && [keyPath isEqualToString:@"backgroundColor"]) {
        UIColor *newColor = change[NSKeyValueChangeNewKey];
        [self updateBackgroundColor:newColor];
    }
}

#pragma mark - Interface Builder

// Quote From WWDC: This is going to be invoked on our view right before it renders into the canvas, and it's a last miniute chance for us to do any additional setup.
- (void)prepareForInterfaceBuilder {
    self.backgroundColor = UIColor.blackColor;
}

@end
