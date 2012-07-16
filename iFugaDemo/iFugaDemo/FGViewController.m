//
//  FGViewController.m
//  iFugaDemo
//
//  Created by  on 12-07-16.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
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
    [_fgController showImage:[UIImage imageNamed:@"Default-Portrait.png"] 
               fromThumbnail:self.imageView];
}
@end
