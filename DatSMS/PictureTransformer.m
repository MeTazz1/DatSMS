//
//  PictureTransformer.m
//  DatSMS
//
//  Created by Christophe Dellac on 10/13/14.
//  Copyright (c) 2014 Christophe Dellac. All rights reserved.
//

#import "PictureTransformer.h"
#import <UIKit/UIKit.h>

@implementation PictureTransformer

+ (BOOL)allowsReverseTransformation {
    return YES;
}

+ (Class)transformedValueClass
{
    return [NSData class];
}

- (id)transformedValue:(id)value
{
    return UIImagePNGRepresentation(value);
}

- (id)reverseTransformedValue:(id)value
{
    return [UIImage imageWithData:value];
}

@end
