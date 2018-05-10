//
//  ApptentiveClause.h
//  Apptentive
//
//  Created by Frank Schmitt on 11/21/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ApptentiveConversation, ApptentiveIndentPrinter;


@interface ApptentiveClause : NSObject <NSSecureCoding>

- (BOOL)criteriaMetForConversation:(ApptentiveConversation *)conversation;
- (BOOL)criteriaMetForConversation:(ApptentiveConversation *)conversation indentPrinter:(ApptentiveIndentPrinter *)indentPrinter;

@end

NS_ASSUME_NONNULL_END
