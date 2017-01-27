//
//  AFTNetworkPagingViewController.m
//  AFTPhotoScroller
//
//  Created by huangkun on 2017/1/26.
//  Copyright © 2017年 huangkun. All rights reserved.
//

#import "AFTNetworkPagingViewController.h"
#import "AFTProgressBar.h"

@interface AFTNetworkPagingViewController () <NSURLSessionDelegate>
@property (nonatomic, strong) NSMutableDictionary <NSNumber *, NSString *> *imageCache;
@property (nonatomic, strong) NSMutableDictionary <NSNumber *, NSURLSessionDownloadTask *> *taskCache;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSMutableArray <AFTProgressBar *> *progressBars;
@end

@implementation AFTNetworkPagingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // delete all local images
    NSString *imageFolder = [self imageFolderPath];
    [NSFileManager.defaultManager removeItemAtPath:imageFolder error:nil];
    [NSFileManager.defaultManager createDirectoryAtPath:imageFolder withIntermediateDirectories:YES attributes:nil error:nil];
    
    // initialize
    self.imageCache = [NSMutableDictionary new];
    self.taskCache = [NSMutableDictionary new];
    self.progressBars = [NSMutableArray new];
    self.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                 delegate:self
                                            delegateQueue:nil];
    
    // load data for paging view
    self.pagingView.dataSource = self;
    self.pagingView.delegate = self;
    self.pagingView.paddingBetweenPages = 6;

    [self.pagingView reloadData];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.session invalidateAndCancel]; // Break retain cycle
}

- (void)dealloc {
    [_taskCache enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSURLSessionTask * _Nonnull obj, BOOL * _Nonnull stop) {
        if (obj.state == NSURLSessionTaskStateRunning) {
            [obj cancel];
        }
    }];
}

- (BOOL)shouldAutorotate {
    return NO;
}

#pragma mark - AFTPagingScrollViewDataSource

- (NSInteger)numberOfPagesInPagingScrollView:(AFTPagingScrollView *)pagingScrollView {
    return [self URLStrings].count;
}

- (UIImage *)pagingScrollView:(AFTPagingScrollView *)pagingScrollView imageForPageAtIndex:(NSInteger)pageIndex {
    UIImage *image = nil;
    NSString *path = self.imageCache[@(pageIndex)];
    if (path) {
        image = [UIImage imageWithContentsOfFile:path];
    } else {
        image = [self placeholderImage];
        [self downloadImageAtPageIndex:pageIndex];
    }
    return image;
}

#pragma mark - AFTPagingScrollViewDelegate

- (void)pagingScrollView:(AFTPagingScrollView *)pagingScrollView imageScrollView:(UIScrollView *)imageScrollView didReuseForPageIndex:(NSInteger)pageIndex {
    
    BOOL needProgress = (self.imageCache[@(pageIndex)] == nil);
    
    // BUG FIX
    if (!needProgress && [[(id)imageScrollView imageView] image] == [self placeholderImage]) {
        [pagingScrollView reloadPageAtIndex:pageIndex];
        return;
    }
    
    AFTProgressBar *progressBar = nil;
    for (UIView *subview in imageScrollView.subviews) {
        if ([subview isKindOfClass:AFTProgressBar.self]) {
            progressBar = (AFTProgressBar *)subview;
            break;
        }
    }
    
    // create progress label
    if (needProgress && !progressBar) {
        progressBar = [AFTProgressBar largeSizedProgressBar];
        [imageScrollView addSubview:progressBar];
        [self.progressBars addObject:progressBar];
    }
    // remove progress label
    else if (!needProgress && progressBar) {
        [progressBar removeFromSuperview];
        return;
    }
    
    // configure progress label
    progressBar.pageIndex = pageIndex;
    [imageScrollView bringSubviewToFront:progressBar];
}

#pragma mark - URLs

- (NSArray <NSString *> *)URLStrings {
    return @[
        //https://dribbble.com/snootyfox (from YYKit demo)
        @"https://d13yacurqjgara.cloudfront.net/users/26059/screenshots/2047158/beerhenge.jpg",
        @"https://d13yacurqjgara.cloudfront.net/users/26059/screenshots/2016158/avalanche.jpg",
        @"https://d13yacurqjgara.cloudfront.net/users/26059/screenshots/1839353/pilsner.jpg",
        @"https://d13yacurqjgara.cloudfront.net/users/26059/screenshots/1833469/porter.jpg",
        @"https://d13yacurqjgara.cloudfront.net/users/26059/screenshots/1521183/farmers.jpg",
        @"https://d13yacurqjgara.cloudfront.net/users/26059/screenshots/1391053/tents.jpg",
        @"https://d13yacurqjgara.cloudfront.net/users/26059/screenshots/1399501/imperial_beer.jpg",
        @"https://d13yacurqjgara.cloudfront.net/users/26059/screenshots/1488711/fishin.jpg",
        @"https://d13yacurqjgara.cloudfront.net/users/26059/screenshots/1466318/getaway.jpg",
    ];
}

#pragma mark - download

- (void)downloadImageAtPageIndex:(NSInteger)pageIndex {
    NSURLSessionDownloadTask *cachedTask = self.taskCache[@(pageIndex)];
    if (cachedTask && cachedTask.state == NSURLSessionTaskStateRunning) {
        return;
    }
    
    NSString *urlString = [self URLStrings][pageIndex];
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSURLSessionDownloadTask *downloadTask = [self.session downloadTaskWithURL:url];
    [downloadTask resume];
    
    self.taskCache[@(pageIndex)] = downloadTask;
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error {
    
    [self.taskCache.copy enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSURLSessionTask * _Nonnull obj, BOOL * _Nonnull stop) {
        if (task == obj) {
            @synchronized (self) {
                self.taskCache[key] = nil;
            }
            *stop = YES;
        }
    }];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    
    __block NSNumber *pageValue = nil;
    [self.taskCache enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSURLSessionDownloadTask * _Nonnull obj, BOOL * _Nonnull stop) {
        if (downloadTask == obj) {
            pageValue = key;
            *stop = YES;
        }
    }];
    
    NSString *filename = [pageValue.stringValue stringByAppendingString:@".jpg"];
    NSString *path = [[self imageFolderPath] stringByAppendingPathComponent:filename];
    
    NSData *data = [NSData dataWithContentsOfURL:location];
    if ([data writeToFile:path atomically:YES]) {
        @synchronized (self) {
            self.imageCache[pageValue] = path;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.pagingView reloadPageAtIndex:pageValue.integerValue];
        });
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    
    __block NSNumber *pageValue = nil;
    [_taskCache enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSURLSessionDownloadTask * _Nonnull obj, BOOL * _Nonnull stop) {
        if (downloadTask == obj) {
            pageValue = key;
            *stop = YES;
        }
    }];
    
    NSInteger pageIndex = pageValue.integerValue;
    double progress = (double)totalBytesWritten / (double)totalBytesExpectedToWrite;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        for (AFTProgressBar *progressBar in self.progressBars) {
            if (progressBar.pageIndex == pageIndex) {
                progressBar.progress = progress;
                if (progress >= 1) {
                    [progressBar removeFromSuperview];
                }
                break;
            }
        }
    });
}

#pragma mark - placeholder image

- (UIImage *)placeholderImage {
    static UIImage *image = nil;
    if (!image) {
        CGSize size = UIScreen.mainScreen.bounds.size;
        UIGraphicsBeginImageContextWithOptions(size, YES, 0.0);
        
        CGRect rect = { CGPointZero, size };
        UIColor *bgColor = [UIColor colorWithRed:0.929 green:0.937 blue:0.945 alpha:1.00];
        UIBezierPath *path = [UIBezierPath bezierPathWithRect:rect];
        [bgColor setFill];
        [path fill];
        
        UIImage *logo = [UIImage imageNamed:@"aft_placeholder_raw"];
        CGSize logoSize = logo.size;
        
        CGFloat x = (size.width - logoSize.width) / 2;
        CGFloat y = (size.height - logoSize.height) / 2;
        
        if (x > 0 && y > 0) {
            [logo drawAtPoint:CGPointMake(x, y)];
        } else {
            CGFloat ratio = logoSize.width / logoSize.height;
            logoSize.width = size.width * 0.9;
            logoSize.height = logo.size.width * ratio;
            x = (size.width - logoSize.width) / 2;
            y = (size.height - logoSize.height) / 2;
            [logo drawInRect:CGRectMake(x, y, logoSize.width, logoSize.height)];
        }
        
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    return image;
}

#pragma mark - file / folder

- (NSString *)imageFolderPath {
    NSString *documentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *imageFolder = [documentPath stringByAppendingPathComponent:@"AFTNetworkPhotos"];
    return imageFolder;
}

@end
