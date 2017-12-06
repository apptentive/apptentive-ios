//
//  ApptentiveInteraction.h
//  Apptentive
//
//  Created by Peter Kamb on 8/23/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ApptentiveInteractionUsageData;


@interface ApptentiveInteraction : NSObject <NSCoding, NSCopying>
@property (copy, nonatomic) NSString *identifier;
@property (assign, nonatomic) NSInteger priority;
@property (copy, nonatomic) NSString *type;
@property (copy, nonatomic) NSDictionary *configuration;
@property (copy, nonatomic) NSString *version;
@property (copy, nonatomic) NSString *vendor;

+ (ApptentiveInteraction *)interactionWithJSONDictionary:(NSDictionary *)jsonDictionary;

// Used to engage local and app events
+ (ApptentiveInteraction *)localAppInteraction;
+ (ApptentiveInteraction *)apptentiveAppInteraction;

- (NSString *)codePointForEvent:(NSString *)event;

@end

NS_ASSUME_NONNULL_END
