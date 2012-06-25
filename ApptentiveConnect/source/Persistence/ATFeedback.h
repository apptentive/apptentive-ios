//
//  ATFeedback.h
//  DemoApp
//
//  Created by Andrew Wooster on 3/16/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#elif TARGET_OS_MAC
#import <AppKit/AppKit.h>
#endif

#import "ATRecord.h"

typedef enum {
	ATFeedbackTypeFeedback,
	ATFeedbackTypePraise,
	ATFeedbackTypeBug,
	ATFeedbackTypeQuestion
} ATFeedbackType;

@interface ATFeedback : ATRecord <NSCoding> {
	NSMutableDictionary *extraData;
}
@property (nonatomic, assign) ATFeedbackType type;
@property (nonatomic, retain) NSString *text;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *email;
@property (nonatomic, retain) NSString *phone;
#if TARGET_OS_IPHONE
@property (nonatomic, retain) UIImage *screenshot;
#elif TARGET_OS_MAC
@property (nonatomic, retain) NSImage *screenshot;
#endif
/*! Used to keep hold of screenshot switch state. */
@property (nonatomic, assign) BOOL screenshotSwitchEnabled;
@property (nonatomic, assign) BOOL imageIsFromCamera;

- (NSDictionary *)dictionary;
- (NSDictionary *)apiDictionary;
- (void)addExtraDataFromDictionary:(NSDictionary *)dictionary;
@end
