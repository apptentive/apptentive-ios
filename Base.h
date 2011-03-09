//
//  Base.h
//  WowieConnect
//
//  Created by Michael Saffitz on 1/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ObjectiveResourceConfig.h"
#import "Connection.h"

@interface Base : NSObject<NSCoding> {
    NSDate *createdAt;
    NSDate *updatedAt;
}

@property (nonatomic, retain) NSDate *createdAt;
@property (nonatomic, retain) NSDate *updatedAt;

@end
