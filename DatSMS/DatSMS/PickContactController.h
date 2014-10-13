//
//  PickContactController.h
//  DatSMS
//
//  Created by Christophe Dellac on 10/9/14.
//  Copyright (c) 2014 Christophe Dellac. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Dat.h"

@interface PickContactController : UIViewController
{
    NSMutableArray *selectedIndex;
}
@property (nonatomic, retain) NSArray *contacts;
@property (nonatomic, retain) Dat *dat;
@end
