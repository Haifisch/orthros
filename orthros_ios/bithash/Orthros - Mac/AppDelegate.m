//
//  AppDelegate.m
//  Orthros - Mac
//
//  Created by haifisch on 7/6/15.
//  Copyright (c) 2015 Haifisch. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate () {
    NSUserDefaults *defaults;
}

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    defaults = [[NSUserDefaults alloc] initWithSuiteName:@"ninja.orthros.group.suite"];
    if (![defaults boolForKey:@"firstLaunch"]) {
        CFUUIDRef uuidObject = CFUUIDCreate(kCFAllocatorDefault);
        
        [defaults setObject: (__bridge_transfer NSString *)uuidObject forKey:@"UUID"];
        CFRelease(uuidObject);
    }
    // Insert code here to initialize your application
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
