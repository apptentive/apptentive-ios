//
//  ATMetric.h
//  ApptentiveMetrics
//
//  Created by Andrew Wooster on 12/27/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ATMetric : NSObject <NSCoding> {
@private
	NSMutableDictionary *info;
}
@property (nonatomic, retain) NSString *name;
@property (nonatomic, assign) NSDate *date;
@property (nonatomic, readonly) NSDictionary *info;

- (void)setValue:(id)value forKey:(NSString *)key;
- (void)addEntriesFromDictionary:(NSDictionary *)dictionary;
@end
