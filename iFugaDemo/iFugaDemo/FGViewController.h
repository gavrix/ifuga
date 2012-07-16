//
//  FGViewController.h
//  iFugaDemo
//
//  Created by  on 12-07-16.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FGController.h"

@interface FGViewController : UIViewController<FGControllerDelegate>
{
    FGController* _fgController;
}
@property (retain, nonatomic) IBOutlet UIImageView *imageView;

@end
