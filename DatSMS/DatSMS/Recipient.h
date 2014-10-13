//
//  Recipient.h
//  DatSMS
//
//  Created by Christophe Dellac on 10/12/14.
//  Copyright (c) 2014 Christophe Dellac. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>

@interface Recipient : NSManagedObject

@property (nonatomic, retain) NSNumber * datId;
@property (nonatomic, retain) NSString * fullname;
@property (nonatomic, retain) NSString * phoneNumber;
@property (nonatomic, retain) UIImage *picture;

@end
