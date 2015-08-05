//
//  DeviceIdentifiers.h
//  bithash
//
//  Created by Haifisch on 2/15/15.
//  Copyright (c) 2015 Haifisch. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DeviceIdentifiers : NSObject
- (NSString*)UUID;
- (NSString *)createUUID;
@end
