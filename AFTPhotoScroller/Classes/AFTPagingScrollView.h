//
//  AFTPagingScrollView.h
//  AFTPhotoScroller
//
//  Created by huangkun on 2017/1/15.
//  Copyright © 2017年 huangkun. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class AFTPagingScrollView;


typedef NS_ENUM(NSInteger, AFTPagingScrollViewNavigationOrientation) {
    AFTPagingScrollViewNavigationOrientationHorizontal  = 0,
    AFTPagingScrollViewNavigationOrientationVertical    = 1,
};


@protocol AFTPagingScrollViewDataSource <NSObject>

/**
 Ask the data source to return the number of pages in the paging scroll view. (要求数据源返回总页数)
 */
- (NSInteger)numberOfPagesInPagingScrollView:(AFTPagingScrollView *)pagingScrollView;

/**
 Ask the data source to return the image for specific page index in the paging scroll view. (要求数据源根据相应的pageIndex返回UIImage对象)
 @warning The returned image object must be not nil. (返回的UIImage对象不可以为nil)
 */
- (UIImage *)pagingScrollView:(AFTPagingScrollView *)pagingScrollView imageForPageAtIndex:(NSInteger)pageIndex;

@end


@protocol AFTPagingScrollViewDelegate <NSObject>

@optional

/**
 Ask the delegate to return the horizontal padding between pages. The default value is 0. (返回页面之间的水平间距，默认值为0)
 */
- (CGFloat)paddingBetweenPagesInPagingScrollView:(AFTPagingScrollView *)pagingScrollView;

/**
 Ask the delegate if the specified page should be displayed on screen. Default is YES. (是否展示指定页面，默认值为YES)
 @warning This method will be called when the specified page is about to show on screen, and it will be called multiple times when user scrolling and constantly checking the result. For performance reason, try not to implement this method heavily. (注意该方法会在翻页过程中被多次调用，为了减少翻页卡顿，该方法的实现必须简洁轻量)
 */
- (BOOL)pagingScrollView:(AFTPagingScrollView *)pagingScrollView shouldDisplayPageAtIndex:(NSInteger)pageIndex;

/**
 Tells the delegate that when the paging view is about to start scrolling the pages. (即将开始手动翻页)
 */
- (void)pagingScrollViewWillBeginPaging:(AFTPagingScrollView *)pagingScrollView;

/**
 Tells the delegate that a specified page is taken more than half of pagingScrollView's size during page-scrolling. (翻页滑动时页面出现在屏幕中，并且占据屏幕一半以上时候的回调方法)
 */
- (void)pagingScrollView:(AFTPagingScrollView *)pagingScrollView didScrollToPageAtIndex:(NSInteger)pageIndex;

/**
 Tells the delegate that a specified page is finally displayed on screen after page-scrolling or -displayPageAtIndex: method is called. (页面最终展示在屏幕上，不论回调来自于是通过翻页滑动，还是调用-displayPageAtIndex:方法)
 */
- (void)pagingScrollView:(AFTPagingScrollView *)pagingScrollView didDisplayPageAtIndex:(NSInteger)pageIndex;

/**
 Tells the delegate that when the paging view is about to start zooming the image. (即将放大或缩小图片)
 @param imageScrollView The inner scroll view which handles the image zooming.
 */
- (void)pagingScrollView:(AFTPagingScrollView *)pagingScrollView imageScrollViewWillBeginZooming:(UIScrollView *)imageScrollView atPageIndex:(NSInteger)pageIndex;

/**
 Tells the delegate that when user scrolls a scaled image for the specified page. (用户通过滑动阅览被放大的图片)
 @param imageScrollView The inner scroll view which handles the image zooming.
 */
- (void)pagingScrollView:(AFTPagingScrollView *)pagingScrollView imageScrollViewDidScrollImage:(UIScrollView *)imageScrollView atPageIndex:(NSInteger)pageIndex;

/**
 Tells the delegate that when the imageScrollView enables a double-tap-to-zoom gesture for its imageView. Using this callback method for additional setup, e.g. [singleTap requireGestureRecognizerToFail:zoomingTap] (创建了双击缩放图片手势的回调，这里可以用于一些附加操作，比如调用-requireGestureRecognizerToFail:)
 @param imageScrollView The inner scroll view which handles the image zooming.
 */
- (void)pagingScrollView:(AFTPagingScrollView *)pagingScrollView imageScrollView:(UIScrollView *)imageScrollView didEnableZoomingTapGesture:(UITapGestureRecognizer *)zoomingTap;

@end


@interface AFTPagingScrollView : UIView

@property (nonatomic, weak) id <AFTPagingScrollViewDelegate> delegate;
@property (nonatomic, weak) id <AFTPagingScrollViewDataSource> dataSource;

/**
 The direction for page scrolling. The default value is horizontal. (翻页滑动方向，默认为水平方向)
 */
@property (nonatomic, assign) AFTPagingScrollViewNavigationOrientation navigationOrientation;

/**
 A floating-point value that specifies the maximum scale factor that can be applied to the image. The default value is 1.0 (图片的最大拉伸参数，默认为1.0)
 */
@property (nonatomic, assign) CGFloat maximumImageZoomScale;

/**
 Whether require a double tap gesture with single touch for zooming image. The default value is YES. (是否启用双击缩放图片的手势，默认为YES)
 */
@property (nonatomic, assign, getter = isZoomingTapEnabled) BOOL zoomingTapEnabled;

/**
 The floating-point value for specifying how much to stretch image by using zooming tap gesture. The value range is from 0 to 1 and default value is 1, which means scaling image to maximum zoom scale. This property only works when zoomingTapEnabled is YES. (指定双击缩放图片手势的图片拉伸进度，范围是0～1，默认为1.0，表示直接拉伸到最大值)
 */
@property (nonatomic, assign) CGFloat zoomingTapProgress;

/**
 Whether applying parallax scrolling effect for page scrolling just like Photo app in iOS 10. The default value is NO. (是否开启视差滚动效果，默认为NO)
 @note If YES, the default padding bewteen pages is 20.0f, which can be modified by implementing -paddingBetweenPagesInPagingScrollView: delegate method. (如果为YES，那么默认的页面视差间距为20，该间距也可以通过实现-paddingBetweenPagesInPagingScrollView:方法来修改)
 */
@property (nonatomic, assign, getter = isParallaxScrollingEnabled) BOOL parallaxScrollingEnabled;

/**
 The current index of pages. (当前页码)
 @note This value will change immediately after user scrolls across half of page. (当用户翻过页面一半的时候，该属性值就会更新)
 */
@property (nonatomic, readonly) NSInteger currentPageIndex;

/**
 The total number of pages. (总页数)
 */
@property (nonatomic, readonly) NSInteger numberOfPages;

/**
 The horizontal padding between pages. (页面之间的水平间隙)
 */
@property (nonatomic, readonly) CGFloat paddingBetweenPages;

/**
 Jump to the specified page. (跳转到某一页)
 @note It will call -pagingScrollView:didDisplayPageAtIndex: delegate method. (该方法会调用-pagingScrollView:didDisplayPageAtIndex:方法)
 */
- (void)displayPageAtIndex:(NSInteger)pageIndex;

/**
 Reload the specified page. (更新某一页的数据)
 @note It will call -pagingScrollView:imageForPageAtIndex: data source method to reload image for given page. (该方法会调用-pagingScrollView:imageForPageAtIndex:方法来重新载入该页所需要展示的图片)
 */
- (void)reloadPageAtIndex:(NSInteger)pageIndex;

/**
 Reload all data to display a pagging view, including the total number of pages and the image for specific page. (重载数据源，更新UI)
 @note This method will build user interface from scratch and call all required methods in AFTPagingScrollViewDataSource.
 */
- (void)reloadData;

@end

NS_ASSUME_NONNULL_END
