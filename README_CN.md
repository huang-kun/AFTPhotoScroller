# AFTPhotoScroller

[![CI Status](http://img.shields.io/travis/huangkun/AFTPhotoScroller.svg?style=flat)](https://travis-ci.org/huangkun/AFTPhotoScroller)
[![Version](https://img.shields.io/cocoapods/v/AFTPhotoScroller.svg?style=flat)](http://cocoapods.org/pods/AFTPhotoScroller)
[![License](https://img.shields.io/cocoapods/l/AFTPhotoScroller.svg?style=flat)](http://cocoapods.org/pods/AFTPhotoScroller)
[![Platform](https://img.shields.io/cocoapods/p/AFTPhotoScroller.svg?style=flat)](http://cocoapods.org/pods/AFTPhotoScroller)

<br />
Check out [English README](https://github.com/huang-kun/AFTPhotoScroller/blob/master/README.md) if you need.
<br />

## 屏幕截图

![翻页与图片缩放](https://github.com/huang-kun/AFTPhotoScroller/blob/master/video1.gif) &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; ![网络加载图片](https://github.com/huang-kun/AFTPhotoScroller/blob/master/video2.gif)


![视差效果](https://github.com/huang-kun/AFTPhotoScroller/blob/master/video3.gif)

## 简介

`AFTPhotoScroller`是一个简单且灵活的照片浏览组件，其实现了iOS照片app的基本功能。

其开发的灵感来自于苹果WWDC2010年的视频[Designing Apps with Scroll Views](https://developer.apple.com/videos/play/wwdc2010/104/)。该视频主要讲解了通过`UIScrollView`的嵌套技巧来实现照片浏览的功能。有很多很棒的开源库都对此作了封装，使得自己的照片浏览框架使用起来更加的容易，但`AFTPhotoScroller`所做的事情却有所不同。

就像经典的照片浏览框架一样，`AFTPhotoScroller`能够实现用户左右翻页图片和对单个图片的放大缩小，不仅如此，它的特性还包含其他方面：

#### 移除Controller的设计

不像`UIPageViewController`，在`AFTPhotoScroller`提供的接口中没有controller，而直接是采用一个叫`AFTPagingScrollView`翻页视图来做照片浏览，这样的话，开发者就可以自己个性化订制自己的controller，这就好比直接使用`UITableView`而非`UITableViewController`的好处一样。它同样实现了`UIPageViewController`自带的页面重用机制、页面间的间距计算、以及做最少量的缓存管理等等，但是不能够实现真实的纸张翻页效果(page curl)和书脊位置(spine location)。

#### 细节订制

允许开发者订制的细节如下：

- 页面之间的间距
- 开启或禁用双击放大或缩小图片的手势
- 给双击手势设置图片放大的尺度，即双击后图片放大效果与最大效果的比例
- 支持垂直方向的翻页
- 支持**视差效果** (体验类似iOS 10的照片app)

允许开发者订制的交互回调如下：

- 是否允许展示某个页面
- 可以直接跳转至某个页面
- 可以重载单个页面 (用于配合网络获取图片后的刷新)
- 获取翻页、缩放手势和双击手势的初始状态
- 获取页面即将完全展示的回调 (即一个页面占据大于屏幕一半位置的时候)

## 示例

首先，`#import <AFTPhotoScroller/AFTPagingScrollView.h>`

在`UIViewController`子类中，只需要简单的加入以下代码即可：

```
- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.pagingView = [[AFTPagingScrollView alloc] initWithFrame:self.view.bounds];
    self.pagingView.delegate = self;
    self.pagingView.dataSource = self;
    [self.view addSubview:self.pagingView];
    
    self.images = ... // load images
    [self.pagingView reloadData]; // build UI and load required data
}

#pragma mark - AFTPagingScrollViewDataSource

- (NSInteger)numberOfPagesInPagingScrollView:(AFTPagingScrollView *)pagingScrollView {
    return self.images.count;
}

- (UIImage *)pagingScrollView:(AFTPagingScrollView *)pagingScrollView imageForPageAtIndex:(NSInteger)pageIndex {
    return self.images[pageIndex];
}

#pragma mark - AFTPagingScrollViewDelegate

- (CGFloat)paddingBetweenPagesInPagingScrollView:(AFTPagingScrollView *)pagingScrollView {
    return 8;
}
```

建议下载github demo，这个demo展示了创建几种不同类型的照片浏览，并且附赠了底部页码条和导航栏的push动画。

当然真正的app中，我们不建议像demo一样一次性加载所有图片到内存中去。

## 注意

- 目前没有适配`IBDesignable`和`IBInspectable`


## 最低系统要求

iOS 6+

## 安装

AFTPhotoScroller可以通过[CocoaPods](http://cocoapods.org)进行安装。只需要在你的Podfile中加入即可。

```ruby
pod "AFTPhotoScroller"
```

## 作者

huangkun, jack-huang-developer@foxmail.com

## 许可

AFTPhotoScroller使用MIT许可，相关内容请查看LICENSE文件。


