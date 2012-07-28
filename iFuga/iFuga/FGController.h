//
//  FGController.h
//  iFuga
//
//  Created by Sergey Gavrilyuk on 12-07-16.
//  Copyright (c) 2012 Sergey Gavrilyuk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIkit.h>

@protocol FGControllerDelegate <NSObject>

@optional
-(BOOL) canRotateToInterfaceOrientation:(UIInterfaceOrientation) orientation;
@end

@interface FGController : NSObject<UIScrollViewDelegate, UIGestureRecognizerDelegate>
{
    UIView* _view;
    UIView* _backgroundView;
    UIScrollView* _scrollView;
    UIView* _mainView;
    UIImageView* _imageView;
    UIView* _thumbView;
    
    UIToolbar* _toolbar;
    
    BOOL _controlsVisible;
    BOOL _showingFullscreen;
}



-(id) initWithDelegate:(id<FGControllerDelegate>) delegate;


//functioinality
-(void) showImage:(UIImage*) image;
-(void) showImage:(UIImage*) image
    fromThumbnail:(UIView*) thumbnailView;

-(void) dismiss;

-(void) dismissAnimated:(BOOL) animated
               finished:(void (^)(void)) finishBloclk;


@property (nonatomic, assign) id<FGControllerDelegate> delegate;
@property (nonatomic, readonly) BOOL showingFullscreen;
@end
