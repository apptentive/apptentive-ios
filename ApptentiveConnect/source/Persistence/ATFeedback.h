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

typedef enum {
	ATFeedbackSourceUnknown,
	ATFeedbackSourceEnjoymentDialog,
} ATFeedbackSource;

typedef enum {
	ATFeedbackImageSourceScreenshot,
	ATFeedbackImageSourceCamera,
	ATFeedbackImageSourcePhotoLibrary,
} ATFeedbackImageSource;

@interface ATFeedback : ATRecord <NSCoding> {
@private
	NSMutableDictionary *extraData;
	ATFeedbackType type;
	NSString *text;
	NSString *name;
	NSString *email;
	NSString *phone;
	ATFeedbackSource source;
#if TARGET_OS_IPHONE
	UIImage *screenshot;
#elif TARGET_OS_MAC
	NSImage *screenshot;
#endif
	ATFeedbackImageSource imageSource;
}
@property (nonatomic, assign) ATFeedbackType type;
@property (nonatomic, retain) NSString *text;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *email;
@property (nonatomic, retain) NSString *phone;
@property (nonatomic, assign) ATFeedbackSource source;
#if TARGET_OS_IPHONE
@property (nonatomic, retain) UIImage *screenshot;
#elif TARGET_OS_MAC
@property (nonatomic, retain) NSImage *screenshot;
#endif
@property (nonatomic, assign) ATFeedbackImageSource imageSource;

- (NSDictionary *)dictionary;
- (NSDictionary *)apiDictionary;
- (void)addExtraDataFromDictionary:(NSDictionary *)dictionary;
@end
