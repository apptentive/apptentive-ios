//
//  NSObject+ATSwizzle.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 11/3/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (ATSwizzle)
- (IMP)at_swizzleSelector:(SEL)originalSelector withIMP:(IMP)newIMP;
@end

void ATSwizzle_NSObject_Bootstrap();
