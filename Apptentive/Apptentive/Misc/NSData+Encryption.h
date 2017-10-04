//
//  NSData+Encryption.h
//  Apptentive
//
//  Created by Frank Schmitt on 5/1/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface NSData (Encryption)

/**
 Encrypts the data using a AES with a 256-bit key.
 It then prepends the initialization vector to the encrypted data. A random 16-byte initialization vector
 would be used.
 
 @param key A 32-byte key to use to encrypt the data
 @return The encrypted data with the initialization vector prepended, or nil if there was an error.
 */
- (nullable NSData *)apptentive_dataEncryptedWithKey:(NSData *)key;


/**
 Encrypts the data using a AES with a 256-bit key. 
 It then prepends the initialization vector to the encrypted data.

 @param key A 32-byte key to use to encrypt the data
 @param initializationVector A 16-byte initialization vector.
 @return The encrypted data with the initialization vector prepended, or nil if there was an error.
 */
- (nullable NSData *)apptentive_dataEncryptedWithKey:(NSData *)key initializationVector:(NSData *)initializationVector;

/**
 For testing purposes, decrypts the data (with a prepended initialization vector)
 using the specified key.

 @param key A 32-byte key used to decrypt the data.
 @return The decrypted data, or nil if there was an error.
 */
- (nullable NSData *)apptentive_dataDecryptedWithKey:(NSData *)key;


/**
 Initializes data based on the base-16 data passed in as a string.

 @param string A series of characters in base-16 to be converted to data.
 @return A newly-initialized data object.
 */
+ (nullable instancetype)apptentive_dataWithHexString:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
