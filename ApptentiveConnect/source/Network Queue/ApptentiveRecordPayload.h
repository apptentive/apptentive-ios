//
//  ApptentiveRecordPayload.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 1/5/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

@protocol ApptentiveRecordPayload <NSObject>

@property (readonly, nonatomic) NSString *path;
@property (readonly, nonatomic) NSDictionary *JSONDictionary;

@end
