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
	// kCCAlgorithmAES128 will use a 256-bit key (AES256) if one is supplied.
	ApptentiveAssertTrue(key.length == 32, @"A 256-bit key is required.");
	CCCryptorStatus err = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, key.bytes, key.length, initializationVector.bytes, self.bytes, self.length, result.mutableBytes, result.length, &resultLength);

	if (err == kCCSuccess) {
		result.length = resultLength;
		NSMutableData *ciphertextData = [initializationVector mutableCopy];
		[ciphertextData appendData:result];

		return ciphertextData;
	} else {
		ApptentiveLogError(@"Failed to encrypt data (error code: %ld)", err);
		return nil;
	}
}

- (NSData *)apptentive_dataDecryptedWithKey:(NSData *)key {
	NSData *initializationVector = [self subdataWithRange:NSMakeRange(0, 16)];
	NSData *inputData = [self subdataWithRange:NSMakeRange(16, self.length - 16)];

	NSMutableData *result = [[NSMutableData alloc] initWithLength:inputData.length];
	size_t resultLength;
	// kCCAlgorithmAES128 will use a 256-bit key (AES256) if one is supplied.
	ApptentiveAssertTrue(key.length == 32, @"A 256-bit key is required.");
	CCCryptorStatus err = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, key.bytes, key.length, initializationVector.bytes, inputData.bytes, inputData.length, result.mutableBytes, result.length, &resultLength);

	if (err == kCCSuccess) {
		result.length = resultLength;

		return result;
	} else {
		ApptentiveLogError(@"Failed to decrypt data (error code: %ld)", err);
		return nil;
	}
}

+ (instancetype)apptentive_dataWithHexString:(NSString *)string {
	ApptentiveAssertTrue(string.length % 2 == 0, @"Key length must be an even number of characters");

	NSMutableData *result = [NSMutableData dataWithCapacity:(string.length / 2)];

	for (NSInteger i = 0; i < string.length; i += 2) {
		NSString *substring = [string substringWithRange:NSMakeRange(i, 2)];
		NSScanner *scanner = [NSScanner scannerWithString:substring];
		unsigned int byte;
		[scanner scanHexInt:&byte];

		[result appendBytes:&byte length:1];
	}

	return result;
}

@end
