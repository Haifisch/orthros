//
//  RSA.h
//  Orthros
//
//  Created by haifisch on 7/14/15.
//  Copyright (c) 2015 Haifisch. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RSA : NSObject {
    SecKeyRef publicKey;
    SecCertificateRef certificate;
    SecPolicyRef policy;
    SecTrustRef trust;
    size_t maxPlainLen;
}

- (NSData *) encryptWithData:(NSData *)content;
- (NSData *) encryptWithString:(NSString *)content;

@end