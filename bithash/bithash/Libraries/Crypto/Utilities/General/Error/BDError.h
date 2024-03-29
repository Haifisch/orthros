//
//  Created by Patrick Hogan/Manuel Zamora 2012
//

#import <Foundation/Foundation.h>
#import "BDLog.h"

////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Forward Declarations
////////////////////////////////////////////////////////////////////////////////////////////////////////////
@class BDError;


////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Public Interface
////////////////////////////////////////////////////////////////////////////////////////////////////////////
@interface BDError : NSObject

@property (nonatomic, retain) NSMutableArray *errors;

- (void)addErrorWithType:(NSString *)errorType
              errorClass:(Class)errorClass;

- (void)appendErrorsFromError:(BDError *)error;

+ (BOOL)errorContainsErrors:(BDError *)error;

+ (BOOL)    error:(BDError *)error
containsErrorType:(NSString *)errorType
       errorClass:(Class)errorClass;

@end