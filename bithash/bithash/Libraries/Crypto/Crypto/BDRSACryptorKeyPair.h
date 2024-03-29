//
//  Created by Patrick Hogan on 10/12/12.
//

#import <Foundation/Foundation.h>
#import "BDError.h"
#import "BDLog.h"

////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Public Interface
////////////////////////////////////////////////////////////////////////////////////////////////////////////
@interface BDRSACryptorKeyPair : NSObject

@property (nonatomic, strong) NSString *publicKey;
@property (nonatomic, strong) NSString *privateKey;

- (id)initWithPublicKey:(NSString *)publicKey
             privateKey:(NSString *)privateKey;

@end
