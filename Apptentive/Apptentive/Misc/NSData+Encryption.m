//
//  NSData+Encryption.m
//  Apptentive
//
//  Created by Frank Schmitt on 5/1/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "NSData+Encryption.h"
#import <CommonCrypto/CommonCrypto.h>


@implementation NSData (Encryption)

- (NSData *)apptentive_dataEncryptedWithKey:(NSData *)key initializationVector:(NSData *)initializationVector {
	NSMutableData *result = [[NSMutableData alloc] initWithLength:self.length + kCCBlockSizeAES128];
	size_t resultLength;
	CCCryptorStatus err = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, key.bytes, key.length, initializationVector.bytes, self.bytes, self.length, result.mutableBytes, result.length, &resultLength);

	if (err == kCCSuccess) {
		result.length = resultLength;
		NSMutableData *ciphertextData = [initializationVector mutableCopy];
		[ciphertextData appendData:result];

		return ciphertextData;
	} else {
		ApptentiveAssertTrue(NO, @"Failed to encrypt data (error code: %ld)", err);
		return nil;
	}
}

- (NSData *)apptentive_dataDecryptedWithKey:(NSData *)key {
	NSData *initializationVector = [self subdataWithRange:NSMakeRange(0, 16)];
	NSData *inputData = [self subdataWithRange:NSMakeRange(16, self.length - 16)];

	NSMutableData *result = [[NSMutableData alloc] initWithLength:inputData.length];
	size_t resultLength;
	CCCryptorStatus err = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, key.bytes, key.length, initializationVector.bytes, inputData.bytes, inputData.length, result.mutableBytes, result.length, &resultLength);

	if (err == kCCSuccess) {
		result.length = resultLength;

		return result;
	} else {
		ApptentiveAssertTrue(NO, @"Failed to decrypt data (error code: %ld)", err);
		return nil;
	}
}

@end
