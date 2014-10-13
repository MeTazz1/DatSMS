//
//  Dat.h
//  DatSMS
//
//  Created by Christophe Dellac on 10/12/14.
//  Copyright (c) 2014 Christophe Dellac. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Dat : NSManagedObject

@property (nonatomic, retain) NSNumber * datId;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) NSMutableArray *recipients;
@end
