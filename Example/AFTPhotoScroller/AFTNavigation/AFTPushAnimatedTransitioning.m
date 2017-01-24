//
//  AFTPushAnimatedTransitioning.m
//  AFTNavigationBar
//
//  Created by huangkun on 2017/1/9.
//  Copyright © 2017年 huangkun. All rights reserved.
//

#import "AFTPushAnimatedTransitioning.h"

@implementation AFTPushAnimatedTransitioning

- (instancetype)initWithPresentedViewController:(UIViewController *)viewController {
    self = [super init];
    if (self) {
        viewController.modalPresentationStyle = UIModalPresentationCustom;
        viewController.transitioningDelegate = self;
    }
    return self;
}

#pragma mark - UIViewControllerTransitioningDelegate

- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    self.dismissing = NO;
    return self;
}

- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    self.dismissing = YES;
    return self;
}

#pragma mark - UIViewControllerAnimatedTransitioning

- (NSTimeInterval)transitionDuration:(nullable id <UIViewControllerContextTransitioning>)transitionContext {
    return 0.5;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    CGFloat damping = 1.0;
    CGFloat velocity = 1.0;
    
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];

    if (!self.isDismissing) {
        
        CGRect initialCoveredFrame = [transitionContext initialFrameForViewController:fromVC];
        CGRect finalCoveredFrame = CGRectOffset(initialCoveredFrame, -initialCoveredFrame.size.width / 4, 0);
        
        CGRect finalPresentedFrame = [transitionContext finalFrameForViewController:toVC];
        toVC.view.frame = CGRectOffset(finalPresentedFrame, finalPresentedFrame.size.width, 0);
        
        UIView *containerView = [transitionContext containerView];
        [containerView addSubview:toVC.view];
        
        [UIView animateWithDuration:duration
                              delay:0.0
             usingSpringWithDamping:damping
              initialSpringVelocity:velocity
                            options:UIViewAnimationOptionCurveLinear
                         animations:^{
                             fromVC.view.frame = finalCoveredFrame;
                             toVC.view.frame = finalPresentedFrame;
                         } completion:^(BOOL finished) {
                             [transitionContext completeTransition:YES];
                         }];
        
    } else {
        
        CGRect initialDismissedFrame = [transitionContext initialFrameForViewController:fromVC];
        CGRect finalDismissedFrame = CGRectOffset(initialDismissedFrame, initialDismissedFrame.size.width, 0);
        CGRect finalCoveredFrame = initialDismissedFrame;
        
        [UIView animateWithDuration:duration
                              delay:0.0
             usingSpringWithDamping:damping
              initialSpringVelocity:velocity
                            options:UIViewAnimationOptionCurveLinear
                         animations:^{
                             fromVC.view.frame = finalDismissedFrame;
                             toVC.view.frame = finalCoveredFrame;
                         } completion:^(BOOL finished) {
                             [transitionContext completeTransition:YES];
                         }];
        
    }
}

@end
