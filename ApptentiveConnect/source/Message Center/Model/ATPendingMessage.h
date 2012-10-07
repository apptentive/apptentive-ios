//
//  ATPendingMessage.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/6/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ATPendingMessage : NSObject <NSCoding> {
	NSString *body;
}
@property (nonatomic, retain) NSString *body;

- (NSDictionary *)apiJSON;
@end
