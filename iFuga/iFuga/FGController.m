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

    [super dealloc];
}
////////////////////////////////////////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UIGestureRecognizerDelegate
////////////////////////////////////////////////////////////////////////////////////////////////////

-(BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return  !CGRectContainsPoint(_toolbar.frame,
                                [gestureRecognizer locationInView:_mainView]);
        
}

////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Internal utility methods
////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Fullscreen
////////////////////////////////////////////////////////////////////////////////////////////////////

-(void) _enterFullscreen
{
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    
    UIWindow* keyWindow = [UIApplication sharedApplication].keyWindow;
    
    _mainView.transform = [self transformForUIInterfaceOrientation:
                       [UIApplication sharedApplication].statusBarOrientation];
    
    [keyWindow addSubview:_view];
    _view.frame = keyWindow.bounds;
    _backgroundView.frame =  _view.bounds;
    
    _backgroundView.alpha = 0;
    
    CGRect thumbnailRect = [_thumbView.superview convertRect:_thumbView.frame toView:keyWindow];
    CGRect fromRect = [_scrollView convertRect:thumbnailRect fromView:keyWindow];
    
    CGFloat wscale = 1;
    CGFloat hscale = 1;
    if(_imageView.image.size.width > _scrollView.bounds.size.width)
        wscale = _scrollView.bounds.size.width/_imageView.image.size.width;
    if(_imageView.image.size.height > _scrollView.bounds.size.height)
        hscale = _scrollView.bounds.size.height/_imageView.image.size.height;         
    CGFloat scale = MIN(wscale, hscale);
    
    CGRect toRect = CGRectMake(ceil((_scrollView.bounds.size.width - _imageView.image.size.width*scale)/2.0),
                               ceil((_scrollView.bounds.size.height - _imageView.image.size.height*scale)/2.0), 
                               _imageView.image.size.width*scale,
                               _imageView.image.size.height*scale);
    
    [CATransaction begin];
    [CATransaction setAnimationDuration:0.66];
    
    [CATransaction setCompletionBlock:^
    {
        _imageView.layer.anchorPoint = CGPointMake(.5, .5);
        
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

        
        [self _setControlsVisible:YES animated:YES];

    }];
    
    _imageView.layer.anchorPoint = CGPointZero;
    
    CABasicAnimation* boundsAnimation = [CABasicAnimation animationWithKeyPath:@"bounds"];
    boundsAnimation.fromValue = [NSValue valueWithCGRect:fromRect];
    boundsAnimation.toValue = [NSValue valueWithCGRect:toRect];
    
    CABasicAnimation* positionAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
    positionAnimation.fromValue = [NSValue valueWithCGPoint:fromRect.origin];
    positionAnimation.toValue = [NSValue valueWithCGPoint:toRect.origin];
    
    CABasicAnimation* alphaAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    alphaAnimation.fromValue = [NSNumber numberWithFloat:0];
    alphaAnimation.toValue = [NSNumber numberWithFloat:1];
    
    [_backgroundView.layer addAnimation:alphaAnimation forKey:nil];
    [_imageView.layer addAnimation:boundsAnimation forKey:nil];
    [_imageView.layer addAnimation:positionAnimation forKey:nil];
    
    [CATransaction commit];
    
    _backgroundView.alpha = 1;
    
    [self _signUpForNotifications];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
-(void) _exitFullscreen
{
    
    [self _setControlsVisible:NO animated:NO];
    UIWindow* keyWindow = [UIApplication sharedApplication].keyWindow;
    
    CGRect fromRect = [_scrollView convertRect:_imageView.frame toView:_mainView];
    
    CGRect thumbnailRect = [_thumbView.superview convertRect:_thumbView.frame toView:keyWindow];
    CGRect toRect = [_scrollView convertRect:thumbnailRect fromView:keyWindow];
    
    _imageView.transform = CGAffineTransformIdentity;
    
    [CATransaction begin];
    [CATransaction setAnimationDuration:0.66];
    

    _imageView.layer.anchorPoint = CGPointZero;
    [CATransaction setCompletionBlock:^
     {
         [_view removeFromSuperview];
         _imageView.layer.anchorPoint = CGPointMake(.5, .5);
         [self _exitShowingExclusively];
     }];



    CABasicAnimation* boundsAnimation = [CABasicAnimation animationWithKeyPath:@"bounds"];
    boundsAnimation.fromValue = [NSValue valueWithCGRect:fromRect];
    boundsAnimation.toValue = [NSValue valueWithCGRect:toRect];

    CABasicAnimation* transformAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    transformAnimation.fromValue = [NSNumber numberWithFloat:_scrollView.zoomScale];
    transformAnimation.toValue = [NSNumber numberWithFloat:1];

    
    CABasicAnimation* positionAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
    positionAnimation.fromValue = [NSValue valueWithCGPoint:fromRect.origin];
    positionAnimation.toValue = [NSValue valueWithCGPoint:toRect.origin];
    
    CABasicAnimation* alphaAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    alphaAnimation.fromValue = [NSNumber numberWithFloat:1];
    alphaAnimation.toValue = [NSNumber numberWithFloat:0];
    
    [_backgroundView.layer addAnimation:alphaAnimation forKey:nil];
    [_imageView.layer addAnimation:boundsAnimation forKey:nil];
    [_imageView.layer addAnimation:positionAnimation forKey:nil];
//    [_imageView.layer addAnimation:transformAnimation forKey:nil];

    
    
    [CATransaction commit];

    _backgroundView.alpha = 0;
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    
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
            [CATransaction setCompletionBlock:^
            {
                _toolbar.hidden = YES;
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
