//
//  Created by Patrick Hogan/Manuel Zamora 2012
//
#import <Foundation/Foundation.h>
#import "BDError.h"
#import "BDLog.h"

////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Public Interface
////////////////////////////////////////////////////////////////////////////////////////////////////////////
@interface NSString (BDUtilities)

+ (BOOL)isEmpty:(NSString *)string;

+ (NSString *)randomStringWithLength:(NSInteger)length;

- (BOOL)containsSubstring:(NSString *)substring;

@end
