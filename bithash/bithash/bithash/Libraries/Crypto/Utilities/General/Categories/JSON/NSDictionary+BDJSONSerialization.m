//
//  Created by Patrick Hogan/Manuel Zamora 2012
//


////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Public Interface
////////////////////////////////////////////////////////////////////////////////////////////////////////////
#import "NSDictionary+BDJSONSerialization.h"

////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Utilities
////////////////////////////////////////////////////////////////////////////////////////////////////////////
#import "BDJSONError.h"


////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Implementation
////////////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation NSDictionary (BDJSONSerialization)


////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Serialization
////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSString *)stringValue:(BDError *)error
{
    return [[NSString alloc] initWithData:[self dataValue:error]
                                 encoding:NSUTF8StringEncoding];
}


- (NSData *)dataValue:(BDError *)error
{
    NSError *unhandledError = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:self
                                                   options:kNilOptions
                                                     error:&unhandledError];
    
    if (unhandledError)
    {
        [error addErrorWithType:BDJSONErrorParse
                          errorClass:[BDJSONError class]];
    }
    
    return data;
}


@end