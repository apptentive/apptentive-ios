//
//  DataPoint.h
//  WowieConnect
//
//  Created by Michael Saffitz on 1/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface DataPoint : NSObject {
    NSString *dataPointId;
    NSString *key;
    NSDate *dateValue;
    NSDecimalNumber *decimalValue;
    NSString *stringValue;
    BOOL replace;
}

@end
