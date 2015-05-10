//
//  AppDelegate.h
//  bithash
//
//  Created by Haifisch on 2/14/15.
//  Copyright (c) 2015 Haifisch. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LTHPasscodeViewController;
@interface AppDelegate : UIResponder <UIApplicationDelegate> {
    LTHPasscodeViewController *_passcodeController;
}

@property (strong, nonatomic) UIWindow *window;


@end

