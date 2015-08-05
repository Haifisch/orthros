//
//  AppDelegate.m
//  bithash
//
//  Created by Haifisch on 2/14/15.
//  Copyright (c) 2015 Haifisch. All rights reserved.
//

#import "AppDelegate.h"
#import "Common.h"
#import "DeviceIdentifiers.h"
#import "bithashTableViewController.h"
#import "LTHPasscodeViewController.h"
@interface AppDelegate () <LTHPasscodeViewControllerDelegate>
{
    DeviceIdentifiers *identify;
    NSUserDefaults *defaults;
}
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    defaults = [[NSUserDefaults alloc] initWithSuiteName:@"ninja.orthros.group.suite"];
    // Override point for customization after application launch.
    [[UITabBar appearance] setTintColor:orthros_purple];
    NSDictionary *button_attributes = @{NSForegroundColorAttributeName:orthros_purple};
    [[UIBarButtonItem appearance] setTitleTextAttributes:button_attributes forState:UIControlStateNormal];
    [[UITabBar appearance] setBarTintColor:[UIColor colorWithRed:33/255.0f green:33/255.0f blue:33/255.0f alpha:1]];
    [[UITabBar appearance] setTranslucent:NO];
    [[UITabBar appearance] setBackgroundImage:[[UIImage alloc] init]];
    [[UITabBar appearance] setShadowImage:[[UIImage alloc] init]];
    
    NSDictionary *title_text_attributes = @{NSForegroundColorAttributeName:[UIColor whiteColor]};
    [[UINavigationBar appearance] setTitleTextAttributes:title_text_attributes];
    [[UINavigationBar appearance] setTintColor:orthros_purple];
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:33/255.0f green:33/255.0f blue:33/255.0f alpha:1]];
    [[UINavigationBar appearance] setTranslucent:NO];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    if ([application respondsToSelector:@selector(registerForRemoteNotificationTypes:)])
    {
        
        UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert |
                                                        UIUserNotificationTypeBadge |
                                                        UIUserNotificationTypeSound);
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes
                                                                                 categories:nil];
        [application registerUserNotificationSettings:settings];
        [application registerForRemoteNotifications];
    }
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BITHASH_URL_CALLED" object:[url host]];
    return YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    const unsigned *tokenBytes = [deviceToken bytes];
    NSString *hexToken = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
                          ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
                          ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
                          ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];
    if (![defaults objectForKey:@"device_token"]) {
        [defaults setObject:hexToken forKey:@"device_token"];
    }
}

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"%@",error);
}
- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    UIView *colourView = [[UIView alloc]initWithFrame:self.window.frame];
    colourView.backgroundColor = [UIColor whiteColor];
    colourView.tag = 1234;
    colourView.alpha = 0;
    [self.window addSubview:colourView];
    [self.window bringSubviewToFront:colourView];
    
    // fade in the view
    [UIView animateWithDuration:0.5 animations:^{
        colourView.alpha = 1;
    }];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    application.applicationIconBadgeNumber = 0;
    UIView *colourView = [self.window viewWithTag:1234];
    colourView.backgroundColor = [UIColor colorWithRed:33/255.0f green:33/255.0f blue:33/255.0f alpha:1];
    [UIView animateWithDuration:0.5 animations:^{
        colourView.alpha = 0;
    } completion:^(BOOL finished) {
        [colourView removeFromSuperview];
    }];
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
