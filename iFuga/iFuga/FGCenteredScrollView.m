//
//  FGCenteredScrollView.m
//  iFuga
//
//  Created by  on 12-07-16.
//  Copyright (c) 2012 Sergey Gavrilyuk. All rights reserved.
//

#import "FGCenteredScrollView.h"

@implementation FGCenteredScrollView

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(viewForZoomingInScrollView:)])
    {
        UIView* zoomedView = [self.delegate viewForZoomingInScrollView:self];
        if(zoomedView)
        {
            CGSize actualSize = CGSizeMake(MAX(self.contentSize.width, self.bounds.size.width),
                                           MAX(self.contentSize.height, self.bounds.size.height));
            zoomedView.center = CGPointMake(actualSize.width/2.0,
                                            actualSize.height/2.0);
        }
    }
}
@end
