//
//  ATFeedback.h
//  DemoApp
//
//  Created by Andrew Wooster on 3/16/11.
//  Copyright 2011 Planetary Scale LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

NSString * const ATContactUpdaterFinished;

@interface ATFeedback : NSObject {
}
@property (nonatomic, retain) NSString *type;
@property (nonatomic, retain) NSString *text;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *email;
@property (nonatomic, retain) NSString *phone;
@property (nonatomic, retain) UIImage *screenshot;
@property (nonatomic, retain) NSString *uuid;
@property (nonatomic, retain) NSString *model;
@property (nonatomic, retain) NSString *os_version;
@property (nonatomic, retain) NSString *carrier;
@property (nonatomic, retain) NSDate *date;

- (NSDictionary *)dictionary;
- (NSDictionary *)apiDictionary;
@end
