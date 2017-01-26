//
//  AFTProgressBar.h
//  AFTPhotoScroller
//
//  Created by huangkun on 2017/1/26.
//  Copyright © 2017年 huangkun. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AFTProgressBar : UIView

@property (nonatomic, assign) NSInteger pageIndex;
@property (nonatomic, assign) double progress; ///< must call -setProgress: on main thread because it will update UI.

+ (instancetype)largeSizedProgressBar;

@end
