//
//  ViewController.h
//  DatSMS
//
//  Created by Christophe Dellac on 10/7/14.
//  Copyright (c) 2014 Christophe Dellac. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

@interface ViewController : UIViewController <UITextViewDelegate>
{
    NSTimer *updateBackgroundTimer;
    int currentPage;
    int nbPages;
    NSMutableArray *_dats;
    NSArray *_contacts;
    AppDelegate *mainDelegate;
}

@property (nonatomic, retain) NSMutableArray *selectedIndex;
@end

