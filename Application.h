//
//  Application.h
//  WowieConnect
//
//  Created by Michael Saffitz on 1/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Base.h"

@interface Application : Base {
    NSString *applicationId;
    NSString *title;
    NSString *appKey;
    NSString *appSecret;
}

@property (nonatomic, retain) NSString *applicationId;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *appKey;
@property (nonatomic, retain) NSString *appSecret;


@end
