//
//  FGController.h
//  iFuga
//
//  Created by Sergey Gavrilyuk on 12-07-16.
//  Copyright (c) 2012 Sergey Gavrilyuk. All rights reserved.

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
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
