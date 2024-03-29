//
//  Created by Patrick Hogan/Manuel Zamora 2012
//

#import <Foundation/Foundation.h>
#import "BDError.h"
#import "BDLog.h"

////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Public Interface
////////////////////////////////////////////////////////////////////////////////////////////////////////////
@interface NSArray (BDJSONSerialization)

- (NSString *)stringValue:(BDError *)error;
- (NSData *)dataValue:(BDError *)error;

@end
