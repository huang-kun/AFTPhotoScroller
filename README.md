# AFTPhotoScroller

[![CI Status](http://img.shields.io/travis/huangkun/AFTPhotoScroller.svg?style=flat)](https://travis-ci.org/huangkun/AFTPhotoScroller)
[![Version](https://img.shields.io/cocoapods/v/AFTPhotoScroller.svg?style=flat)](http://cocoapods.org/pods/AFTPhotoScroller)
[![License](https://img.shields.io/cocoapods/l/AFTPhotoScroller.svg?style=flat)](http://cocoapods.org/pods/AFTPhotoScroller)
[![Platform](https://img.shields.io/cocoapods/p/AFTPhotoScroller.svg?style=flat)](http://cocoapods.org/pods/AFTPhotoScroller)

## ScreenShots

![Paging and zooming](https://github.com/huang-kun/AFTPhotoScroller/blob/master/video1.gif) &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; ![Web image](https://github.com/huang-kun/AFTPhotoScroller/blob/master/video2.gif) 


![Parallax Scrolling1](https://github.com/huang-kun/AFTPhotoScroller/blob/master/video3.gif)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;![Parallax Scrolling2](https://github.com/huang-kun/AFTPhotoScroller/blob/master/video4.gif)

## Introduction

- [中文介绍请戳这里](https://github.com/huang-kun/AFTPhotoScroller/blob/master/README_CN.md)

<br />

`AFTPhotoScroller` is a simple and flexible solution for implementing a photo scroller with the basic functionality in iOS photo app. 

The inspiration of this is from WWDC 2010 video [Designing Apps with Scroll Views](https://developer.apple.com/videos/play/wwdc2010/104/), which explains the essence of nested scroll views technique for photo scrolling. There are some great open source projects wrapping everything to make photo scrolling code simple to implement, but `AFTPhotoScroller` is different.

Like classic photo scroller, `AFTPhotoScroller` can do left to right page scrolling and single photo zooming. The features of `AFTPhotoScroller` are:

#### Controller-Free Design. 

Unlike `UIPageViewController`, there is no controller class for `AFTPhotoScroller`. This is a view-based public interface and the only one needed class is called `AFTPagingScrollView`, which means you can do much customized controller for different situations like using `UITableView` directly instead of `UITableViewController`. It handles the page reuse, padding calculation and minimum image cache concept just like `UIPageViewController`, except the page curl effect and spine location.

#### Customized

There are a lot of details for you to customize:

- Padding between pages
- Enable / disable the double tap gesture to zoom image
- Set zooming progress to determine how far a double tap can zoom.
- Vertical paging direction support
- **Parallax Scrolling** support (like photo app in iOS 10. Check out wikipedia for the concept of [Parallax Scrolling](https://en.wikipedia.org/wiki/Parallax_scrolling) if you like)

There are a lot of control flows for you to customize:

- You can decide whether should display a single page 
- You can jump to specified page directly
- You can reload a single page (It works well with image network fetching)
- You can get callback for beginning states of paging, zooming, tapping. 
- You can get callback after a new page is about to fully displayed on screen (When a new page is taken more than half of the screen)

## Demo

#### Objective-C

First, install `AFTPhotoScroller`.
Then `#import <AFTPhotoScroller/AFTPhotoScroller.h>`
In your `UIViewController` subclass, you can simply just do this.

```
- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.pagingView = [[AFTPagingScrollView alloc] initWithFrame:self.view.bounds];
    self.pagingView.dataSource = self;
    self.pagingView.paddingBetweenPages = 6;
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
```

#### Swift

First, install `AFTPhotoScroller` (**MUST `use_frameworks!` in Podfile**)
Then `import AFTPhotoScroller`
In your `UIViewController` subclass, you can simply just do this.

```
import UIKit
import AFTPhotoScroller

class ViewController: UIViewController, AFTPagingScrollViewDataSource {
    
    var pagingView: AFTPagingScrollView!
    var images: [UIImage]!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        pagingView = AFTPagingScrollView(frame:view.bounds)
        pagingView.isParallaxScrollingEnabled = true
        pagingView.dataSource = self
        view.addSubview(pagingView)
        
        images = loadAllImages()
        pagingView.reloadData()
    }

    public func numberOfPages(in pagingScrollView: AFTPagingScrollView) -> Int {
        return images.count
    }
    
    public func pagingScrollView(_ pagingScrollView: AFTPagingScrollView, imageForPageAt pageIndex: Int) -> UIImage {
        return images[pageIndex]
    }

    func loadAllImages() -> [UIImage] {
        ....
    }
}
```

The demo app is available for downloading. It is showing how to build different photo scrollers by `AFTPhotoScroller`. It works well with other UI component like custom bottom page bar. The demo is using presented navigation bar with push animation instead of real `UINavigationController`.

Unlike demo app, we do not recommend loading all image resources into memory at once in real project.

## Requirements

iOS 6+ 

## Installation

AFTPhotoScroller is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "AFTPhotoScroller"
```

## Thanks

- WWDC Sample Code - [PhotoScroller](https://github.com/robertwalker/PhotoScroller)(ARC version).
- The local image resources are from [unsplash](http://unsplash.com) in [MJParallaxCollectionView](https://github.com/mayuur/MJParallaxCollectionView).
- The web image resources are from [dribbble](https://dribbble.com/snootyfox) in [YYKit](https://github.com/ibireme/YYKit).

## Author

huangkun, jack-huang-developer@foxmail.com

## License

AFTPhotoScroller is available under the MIT license. See the LICENSE file for more info.


