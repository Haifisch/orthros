//
//  Created by Patrick Hogan/Manuel Zamora 2012
//

#import <Foundation/Foundation.h>
#import "BDError.h"
#import "BDLog.h"

////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Public Interface
////////////////////////////////////////////////////////////////////////////////////////////////////////////
@interface NSObject (BDJSONSerialization)

- (NSData *)dataValue:(BDError *)error;
- (NSString *)stringValue:(BDError *)error;
- (NSMutableDictionary *)JSONObject:(BDError *)error;
- (NSMutableArray *)JSONArray:(BDError *)error;

@end