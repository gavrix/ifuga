//
//  FGViewController.m
//  iFugaDemo
//
//  Created by Sergey Gavrilyuk on 12-07-16.
//  Copyright (c) 2012 Sergey Gavrilyuk. All rights reserved.
//
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

#import "FGViewController.h"

@interface FGViewController ()

@end

@implementation FGViewController
@synthesize imageView;

- (void)viewDidLoad
{
    [super viewDidLoad];
    UITapGestureRecognizer* gr = [[UITapGestureRecognizer alloc] initWithTarget:self 
                                                                         action:@selector(imagedTaped)];
    
    [self.imageView addGestureRecognizer:gr];
    [gr release];
    
    [_fgController release];
    _fgController = [[FGController alloc] initWithDelegate:self];
}

- (void)viewDidUnload
{
    [self setImageView:nil];
    [super viewDidUnload];

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
//    return NO;
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)dealloc 
{
    [imageView release];
    [_fgController release];
    [super dealloc];
}

-(void) imagedTaped
{
    [_fgController showImage:[UIImage imageNamed:@"11278-bluemarblewest.jpg"] 
               fromThumbnail:self.imageView];

//    [_fgController showImage:[UIImage imageNamed:@"11278-bluemarblewest.jpg"] ];
}

-(BOOL)canRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    return UIInterfaceOrientationIsPortrait(orientation);
}
@end
