//
//  NSData+Encryption.h
//  Apptentive
//
//  Created by Frank Schmitt on 5/1/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSData (Encryption)

- (NSData *)apptentive_dataEncryptedWithKey:(NSData *)key initializationVector:(NSData *)initializationVector;

#pragma mark - Test

- (NSData *)apptentive_dataDecryptedWithKey:(NSData *)key;

@end
