//
//  AFTPushAnimatedTransitioning.h
//  AFTNavigationBar
//
//  Created by huangkun on 2017/1/9.
//  Copyright © 2017年 huangkun. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AFTPushAnimatedTransitioning : NSObject <UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning>

/// The designated initializer
- (instancetype)initWithPresentedViewController:(UIViewController *)viewController;

/// YES means dismissing, NO means presenting. The default value is NO.
@property (nonatomic, getter = isDismissing) BOOL dismissing;


@end
