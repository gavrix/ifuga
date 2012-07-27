//
//  FGController.m
//  iFuga
//
//  Created by Sergey Gavrilyuk on 12-07-16.
//  Copyright (c) 2012 Sergey Gavrilyuk. All rights reserved.
//

#import "FGController.h"
#import "FGCenteredScrollView.h"

#import <QuartzCore/QuartzCore.h>
static BOOL __isInstanceOfFGControllerShowing;


#define UI_DEBUG 0

@interface FGController ()
-(void) _signUpForNotifications;
-(void) _releaseNotifications;
-(CGAffineTransform) transformForUIInterfaceOrientation:(UIInterfaceOrientation) orientation;
-(UIImage*) imageFromView:(UIView*)view;
@end



@implementation FGController
@synthesize delegate;

////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Construction && destruction
////////////////////////////////////////////////////////////////////////////////////////////////////

-(id) initWithDelegate:(id<FGControllerDelegate>) delegateObj
{
    self = [super init];
    if(self)
    {
        _view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _view.backgroundColor = [UIColor clearColor];
        
        _backgroundView = [[UIView alloc] initWithFrame:_view.bounds];
        _backgroundView.backgroundColor = [UIColor blackColor];
        _backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        
#if UI_DEBUG
        _backgroundView.layer.borderColor = [UIColor blueColor].CGColor;
        _backgroundView.layer.borderWidth = 3;
#endif
        
                
        _scrollView = [[FGCenteredScrollView alloc] initWithFrame:_view.bounds];
        _scrollView.delegate = self;
        _scrollView.backgroundColor = [UIColor clearColor];
        _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        
        
        _mainView = [[UIView alloc] initWithFrame:_view.bounds];
        _mainView.backgroundColor = [UIColor clearColor];
        
        UITapGestureRecognizer* gr = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                             action:@selector(viewTapped)];
        gr.delegate = self;
        [_mainView addGestureRecognizer:gr];
//        gr.cancelsTouchesInView = NO;
        [gr release];
        
#if UI_DEBUG
        _mainView.layer.borderWidth = 3;
        _mainView.layer.borderColor = [UIColor greenColor].CGColor;
#endif
        
        _imageView = [[UIImageView alloc] initWithFrame:_scrollView.bounds];
        _imageView.backgroundColor = [UIColor clearColor];
        
        [_scrollView addSubview:_imageView];
        
        
        _toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, _view.bounds.size.width,0)];
        [_toolbar sizeToFit];
        _toolbar.barStyle = UIBarStyleBlackTranslucent;
        _toolbar.items = [NSArray arrayWithObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone 
                                                                         target:self
                                                                         action:@selector(doneButtonPressed)]];
        _toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin;
        _toolbar.hidden = YES;

        [_mainView addSubview:_scrollView];
        [_mainView addSubview:_toolbar];
        
        [_view addSubview:_backgroundView];
        [_view addSubview:_mainView];


        self.delegate = delegateObj;
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)dealloc
{
    [_view release];
    [_thumbView release];
    [_backgroundView release];
    [_scrollView release];
    [_mainView release];
    [_imageView release];

    [super dealloc];
}
////////////////////////////////////////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UIGestureRecognizerDelegate
////////////////////////////////////////////////////////////////////////////////////////////////////

-(BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if(CGRectContainsPoint(_scrollView.frame,
                           [gestureRecognizer locationInView:_mainView]))
    {
        if(_controlsVisible)
            return  !CGRectContainsPoint(_toolbar.frame,
                                         [gestureRecognizer locationInView:_mainView]);
        else
            return YES;
    }

    return NO;
    
}

////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Internal utility methods
////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Fullscreen
////////////////////////////////////////////////////////////////////////////////////////////////////

-(void) _enterFullscreen
{
    
    UIWindow* keyWindow = [UIApplication sharedApplication].keyWindow;
    
    _mainView.transform = [self transformForUIInterfaceOrientation:
                       [UIApplication sharedApplication].statusBarOrientation];
    
    [keyWindow addSubview:_view];
    _view.frame = keyWindow.bounds;
    _mainView.frame = _view.bounds;
    _backgroundView.frame =  _view.bounds;
    
    _backgroundView.alpha = 0;
    
    _imageView.frame = _scrollView.bounds;


    UIImageView* transitionView = [[[UIImageView alloc] initWithFrame:_thumbView.frame] autorelease];
    transitionView.image = [self imageFromView:_thumbView];
    [_scrollView addSubview:transitionView];
    
    _imageView.frame = CGRectMake(ceil((_scrollView.bounds.size.width - _imageView.image.size.width)/2.0),
                                  ceil((_scrollView.bounds.size.height - _imageView.image.size.height)/2.0), 
                                  _imageView.image.size.width,
                                  _imageView.image.size.height);
    
    
    CGFloat wscale = 1;
    CGFloat hscale = 1;
    
    if(_imageView.image.size.width > _scrollView.bounds.size.width)
        wscale = _scrollView.bounds.size.width/_imageView.image.size.width;
    if(_imageView.image.size.height > _scrollView.bounds.size.height)
        hscale = _scrollView.bounds.size.height/_imageView.image.size.height;         
    _scrollView.minimumZoomScale = MIN(wscale, hscale);
    _scrollView.zoomScale = _scrollView.minimumZoomScale;
    

    CGPoint thumbnailCenter = [_thumbView.superview convertPoint:_thumbView.center toView:keyWindow];
    CGPoint fromCenter = [_scrollView convertPoint:thumbnailCenter fromView:keyWindow];

    
    [CATransaction begin];
    [CATransaction setAnimationDuration:0.66];

    [CATransaction setCompletionBlock:^
    {
        
        transitionView.alpha = 1;
        _imageView.alpha = 1;
        [_imageView.layer removeAnimationForKey:@"imageViewAnimations"];
        [transitionView removeFromSuperview];
        
        [self _setControlsVisible:YES animated:YES];

    }];
    
    transitionView.alpha = 0;
    _imageView.alpha = 0;

    CABasicAnimation* positionAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
    positionAnimation.fromValue = [NSValue valueWithCGPoint:fromCenter];
    positionAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(_scrollView.bounds.size.width/2.0, _scrollView.bounds.size.height/2.0)];
    
    CABasicAnimation* imageViewScaleWidthAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale.x"];
    imageViewScaleWidthAnimation.fromValue = [NSNumber numberWithFloat:_thumbView.frame.size.width/_imageView.image.size.width];
    imageViewScaleWidthAnimation.toValue = [NSNumber numberWithFloat:_scrollView.zoomScale];

    CABasicAnimation* imageViewScaleHeightAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale.y"];
    imageViewScaleHeightAnimation.fromValue = [NSNumber numberWithFloat:_thumbView.frame.size.height/_imageView.image.size.height];
    imageViewScaleHeightAnimation.toValue = [NSNumber numberWithFloat:_scrollView.zoomScale];


    CABasicAnimation* fadeInAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeInAnimation.fromValue = [NSNumber numberWithFloat:0];
    fadeInAnimation.toValue = [NSNumber numberWithFloat:1];
    
    CABasicAnimation* fadeOutAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeOutAnimation.fromValue = [NSNumber numberWithFloat:1];
    fadeOutAnimation.toValue = [NSNumber numberWithFloat:0];
    

    CABasicAnimation* thumbViewScaleWidthAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale.x"];
    thumbViewScaleWidthAnimation.fromValue = [NSNumber numberWithFloat:1];
    thumbViewScaleWidthAnimation.toValue = [NSNumber numberWithFloat:
                                            _imageView.image.size.width/_thumbView.frame.size.width*_scrollView.zoomScale];

    CABasicAnimation* thumbViewScaleHeightAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale.y"];
    thumbViewScaleHeightAnimation.fromValue = [NSNumber numberWithFloat:1];
    thumbViewScaleHeightAnimation.toValue = [NSNumber numberWithFloat:
                                             _imageView.image.size.height/_thumbView.frame.size.height*_scrollView.zoomScale];
    
    
    [_backgroundView.layer addAnimation:fadeInAnimation forKey:nil];
    
    
    CAAnimationGroup* imageViewAnimationsGroup = [CAAnimationGroup animation];
    imageViewAnimationsGroup.animations = [NSArray arrayWithObjects:
                                           positionAnimation, 
                                           imageViewScaleWidthAnimation, 
                                           imageViewScaleHeightAnimation,
                                           fadeInAnimation, nil];


    imageViewAnimationsGroup.fillMode = kCAFillModeForwards;
    imageViewAnimationsGroup.removedOnCompletion = NO;    
    [_imageView.layer addAnimation:imageViewAnimationsGroup forKey:@"imageViewAnimations"];
//    
    CAAnimationGroup* thumbViewAnimationsGroup = [CAAnimationGroup animation];
    thumbViewAnimationsGroup.animations = [NSArray arrayWithObjects:
                                           thumbViewScaleWidthAnimation, 
                                           thumbViewScaleHeightAnimation, 
                                           fadeOutAnimation,
                                           positionAnimation, nil];

    thumbViewAnimationsGroup.timingFunction = imageViewAnimationsGroup.timingFunction;    
    
    [transitionView.layer addAnimation:thumbViewAnimationsGroup forKey:nil];
    [CATransaction commit];
    
    _backgroundView.alpha = 1;
    [[UIApplication sharedApplication] setStatusBarHidden:YES
                                            withAnimation:UIStatusBarAnimationFade];


    [self _signUpForNotifications];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
-(void) _exitFullscreen
{
    
    [self _setControlsVisible:NO animated:NO];
    UIWindow* keyWindow = [UIApplication sharedApplication].keyWindow;
    
    
    CGPoint fromPosition = _imageView.center;//[_scrollView convertPoint:_imageView.center toView:_scrollView];
    CGPoint thumbnailCenter = [_thumbView.superview convertPoint:_thumbView.center toView:keyWindow];
    CGPoint toPosition = [_scrollView convertPoint:thumbnailCenter fromView:keyWindow];
    
    CGFloat scale = _scrollView.zoomScale;//[[_imageView.layer valueForKey:@"transform.scale.x"] floatValue];
    
    _imageView.transform = CGAffineTransformIdentity;
    
    UIImageView* transitionView = [[[UIImageView alloc] initWithFrame:_thumbView.frame] autorelease];
    transitionView.image = [self imageFromView:_thumbView];
    [_scrollView addSubview:transitionView];
    
    _imageView.alpha = 0;
    transitionView.alpha = 0;
    
    //tricky way to stop any scrolling in place
    [_scrollView setContentOffset:_scrollView.contentOffset animated:NO];
    
    [CATransaction begin];
    [CATransaction setAnimationDuration:0.66];
    

    [CATransaction setCompletionBlock:^
     {
         [transitionView removeFromSuperview];
         [_view removeFromSuperview];
         _imageView.alpha = 1;

         [self _exitShowingExclusively];
     }];



    
    CABasicAnimation* positionAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
    positionAnimation.fromValue = [NSValue valueWithCGPoint:fromPosition];
    positionAnimation.toValue = [NSValue valueWithCGPoint:toPosition];
    
    CABasicAnimation* fadeOutAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeOutAnimation.fromValue = [NSNumber numberWithFloat:1];
    fadeOutAnimation.toValue = [NSNumber numberWithFloat:0];

    CABasicAnimation* fadeInAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeInAnimation.fromValue = [NSNumber numberWithFloat:0];
    fadeInAnimation.toValue = [NSNumber numberWithFloat:1];

    CABasicAnimation* imageViewScaleWidthAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale.x"];
    imageViewScaleWidthAnimation.fromValue = [NSNumber numberWithFloat:scale];
    imageViewScaleWidthAnimation.toValue = [NSNumber numberWithFloat:_thumbView.frame.size.width/_imageView.image.size.width];
    
    CABasicAnimation* imageViewScaleHeightAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale.y"];
    imageViewScaleHeightAnimation.fromValue = [NSNumber numberWithFloat:scale];
    imageViewScaleHeightAnimation.toValue = [NSNumber numberWithFloat:_thumbView.frame.size.height/_imageView.image.size.height];

    CABasicAnimation* transitionViewScaleWidthAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale.x"];
    transitionViewScaleWidthAnimation.fromValue = [NSNumber numberWithFloat:_imageView.image.size.width/_thumbView.frame.size.width*scale];
    transitionViewScaleWidthAnimation.toValue = [NSNumber numberWithFloat:1];
    
    CABasicAnimation* transitionViewScaleHeightAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale.y"];
    transitionViewScaleHeightAnimation.fromValue = [NSNumber numberWithFloat:_imageView.image.size.height/_thumbView.frame.size.height*scale];
    transitionViewScaleHeightAnimation.toValue = [NSNumber numberWithFloat:1];

    
    [_backgroundView.layer addAnimation:fadeOutAnimation forKey:nil];

    CAAnimationGroup* imageViewAnimations = [CAAnimationGroup animation];
    imageViewAnimations.animations = [NSArray arrayWithObjects:
                                      fadeOutAnimation,
                                      imageViewScaleWidthAnimation,
                                      imageViewScaleHeightAnimation,
                                      positionAnimation,
                                      nil];

    
    [_imageView.layer addAnimation:imageViewAnimations forKey:nil];

    CAAnimationGroup* transitionViewAnimations = [CAAnimationGroup animation];
    transitionViewAnimations.animations = [NSArray arrayWithObjects:
                                           fadeInAnimation,
                                           transitionViewScaleHeightAnimation,
                                           transitionViewScaleWidthAnimation,
                                           positionAnimation,
                                           nil];
    
    [transitionView.layer addAnimation:transitionViewAnimations forKey:nil];
    
    
    [CATransaction commit];

    _backgroundView.alpha = 0;
    [[UIApplication sharedApplication] setStatusBarHidden:NO
                                            withAnimation:UIStatusBarAnimationFade];
    
    [self _releaseNotifications];
}

////////////////////////////////////////////////////////////////////////////////////////////////////





////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Exclusiveness
////////////////////////////////////////////////////////////////////////////////////////////////////

-(void) _tryShowingExclusivlely
{
    if(__isInstanceOfFGControllerShowing)
    {
        [[NSException exceptionWithName:@"FGControllerException"
                                reason:@"Another instance of FGController is already shown in fullscreen"
                              userInfo:nil] raise];
    }
    else
        __isInstanceOfFGControllerShowing = YES;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
-(void) _exitShowingExclusively
{
    __isInstanceOfFGControllerShowing = NO;
}
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Notifications related
////////////////////////////////////////////////////////////////////////////////////////////////////

-(void) _signUpForNotifications
{
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(statusBarOrientationWillChangeNotification:)
                                                 name:UIApplicationWillChangeStatusBarOrientationNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(statusBarOrientationDidChangeNotification:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
    
    
}


////////////////////////////////////////////////////////////////////////////////////////////////////
-(void) _releaseNotifications
{
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:UIDeviceOrientationDidChangeNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:UIApplicationWillChangeStatusBarOrientationNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:UIApplicationDidChangeStatusBarOrientationNotification
                                                  object:nil];
    
}
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Controls visibility

-(void) _setControlsVisible:(BOOL)visible animated:(BOOL) animated
{
    if(_controlsVisible && !visible)
    {
        if(animated)
        {
            [CATransaction begin];

            _toolbar.alpha = 0;
            [CATransaction setCompletionBlock:^
            {
                _toolbar.hidden = YES;
                _toolbar.alpha = 1;
            }];
            CABasicAnimation* opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
            opacityAnimation.fromValue = [NSNumber numberWithFloat:1];
            opacityAnimation.toValue = [NSNumber numberWithFloat:0];
            [_toolbar.layer addAnimation:opacityAnimation forKey:nil];
            [CATransaction commit];
        }
        else
            _toolbar.hidden = YES;
    }
    else if(!_controlsVisible && visible)
    {
        _toolbar.hidden = NO;
        
        if(animated)
        {
            CABasicAnimation* opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
            opacityAnimation.fromValue = [NSNumber numberWithFloat:0];
            opacityAnimation.toValue = [NSNumber numberWithFloat:1];
            [_toolbar.layer addAnimation:opacityAnimation forKey:nil];

        }   
    }
    _controlsVisible = !_controlsVisible;    
}

////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark- Utilities
////////////////////////////////////////////////////////////////////////////////////////////////////

-(CGAffineTransform) transformForUIInterfaceOrientation:(UIInterfaceOrientation) orientation
{
    CGFloat angle = 0;
    
    switch (orientation)
    {
        case UIInterfaceOrientationLandscapeLeft:
            angle = -M_PI_2;
            break;
        case UIInterfaceOrientationLandscapeRight:
            angle = M_PI_2;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            angle = M_PI;
            break;
        default:
            break;
    }

    return CGAffineTransformMakeRotation(angle);

}

////////////////////////////////////////////////////////////////////////////////////////////////////
-(UIImage*) imageFromView:(UIView*)view
{
    if(!view)
        return nil;
    
    UIGraphicsBeginImageContextWithOptions(view.frame.size, YES, 0);
    
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage* img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return img;
}

////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark- Notification listeners
////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)orientationChanged:(NSNotification *)notification
{
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    if (UIDeviceOrientationIsValidInterfaceOrientation(deviceOrientation))
    {
        [[UIApplication sharedApplication] setStatusBarOrientation:(UIInterfaceOrientation)deviceOrientation
                                                          animated:YES];
    }
    
}


////////////////////////////////////////////////////////////////////////////////////////////////////
-(void) statusBarOrientationWillChangeNotification:(NSNotification*)notification
{
    UIInterfaceOrientation newOrientation = 
    (UIInterfaceOrientation)[[[notification userInfo] objectForKey:UIApplicationStatusBarOrientationUserInfoKey] intValue];

    if(self.delegate && [self.delegate respondsToSelector:@selector(canRotateToInterfaceOrientation:)])
    {
        if(![self.delegate canRotateToInterfaceOrientation:newOrientation])
            return;
    }
    
    CGAffineTransform transform = [self transformForUIInterfaceOrientation:newOrientation];

    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    _view.frame = [UIApplication sharedApplication].keyWindow.bounds;
    
    _backgroundView.frame = _view.bounds;
    
    
    [CATransaction commit];
    [UIView animateWithDuration:[UIApplication sharedApplication].statusBarOrientationAnimationDuration
                     animations:^
     {

         _mainView.transform = transform;
         _mainView.frame = _view.bounds;
         
         
         CGFloat wscale = 1;
         CGFloat hscale = 1;
         if(_imageView.image.size.width > _scrollView.bounds.size.width)
             wscale = _scrollView.bounds.size.width/_imageView.image.size.width;
         if(_imageView.image.size.height > _scrollView.bounds.size.height)
             hscale = _scrollView.bounds.size.height/_imageView.image.size.height;
         
         BOOL wasMinimumScale = ABS(_scrollView.zoomScale - _scrollView.minimumZoomScale)<.01;
         _scrollView.minimumZoomScale = MIN(wscale, hscale);
         if(wasMinimumScale)
             _scrollView.zoomScale = _scrollView.minimumZoomScale;
         
         _imageView.center = CGPointMake(_scrollView.frame.size.width/2.0,
                                         _scrollView.frame.size.height/2.0);
         
         
         
     }];
    

}


////////////////////////////////////////////////////////////////////////////////////////////////////
-(void) statusBarOrientationDidChangeNotification:(NSNotification*)notification
{
    
}
////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark- UIScrollViewDelegate
////////////////////////////////////////////////////////////////////////////////////////////////////

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return _imageView;
}
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark- Functionality
////////////////////////////////////////////////////////////////////////////////////////////////////

-(void) showImage:(UIImage*) image
{
    [self _tryShowingExclusivlely];
    

    
}

////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)showImage:(UIImage *)image fromThumbnail:(UIView *)thumbnailView
{
    [self _tryShowingExclusivlely];
    _imageView.image = image;

    [_thumbView release];
    _thumbView = [thumbnailView retain];
    
    [self _enterFullscreen];
    
}

////////////////////////////////////////////////////////////////////////////////////////////////////
-(void) dismiss
{
    [self dismissAnimated:NO finished:nil];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)dismissAnimated:(BOOL)animated finished:(void (^)(void))finishBloclk
{
    [self _exitFullscreen];
}



////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - User interaction handlers
////////////////////////////////////////////////////////////////////////////////////////////////////

-(void) doneButtonPressed
{
    [self dismissAnimated:YES
                 finished:nil];
}

-(void) viewTapped
{
    [self _setControlsVisible:!_controlsVisible 
                     animated:YES];
}
@end
