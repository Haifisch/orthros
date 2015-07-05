//
//  ConfigureTableViewController.m
//  bithash
//
//  Created by Haifisch on 4/6/15.
//  Copyright (c) 2015 Haifisch. All rights reserved.
//

#import "ConfigureTableViewController.h"
#import "DeviceIdentifiers.h"
#import "JNKeychain.h"
#import "Common.h"
#import "LTHPasscodeViewController.h"
@interface ConfigureTableViewController () <LTHPasscodeViewControllerDelegate> {
    DeviceIdentifiers *identify;
    BOOL isObliterating;
}

@property (strong, nonatomic) IBOutlet UISwitch *passSwitch;
@property (strong, nonatomic) IBOutlet UILabel *uuidLabel;
@end

@implementation ConfigureTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    identify = [[DeviceIdentifiers alloc] init];
    [self.uuidLabel setText:[identify UUID]];
    isObliterating = NO;
}
-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.passSwitch setOnTintColor:[UIColor purpleColor]];
    if ([LTHPasscodeViewController doesPasscodeExist]) {
        [self.passSwitch setOn:YES animated:YES];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)done:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)passcodeToggle:(id)sender {
    UISwitch *swch = (UISwitch *)sender;
    if (!swch.isOn) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"pcb"];
        [[LTHPasscodeViewController sharedUser] showForDisablingPasscodeInViewController:self
                                                                                 asModal:YES];
    } else {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"pcb"];
        [[LTHPasscodeViewController sharedUser] showForEnablingPasscodeInViewController:self
                                                                                asModal:YES];
    }
}
- (IBAction)passcodechange:(id)sender {
    [[LTHPasscodeViewController sharedUser] showForChangingPasscodeInViewController:self asModal:YES];
}

- (IBAction)atomicBomb:(id)sender {
    // obliterate keys
    UIAlertController *warning = [UIAlertController alertControllerWithTitle:@"Warning!" message:@"You're about to obliterate your keys from this device, are you sure you want to continue?" preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *obliterateAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * __nonnull action) {
        isObliterating = YES;
        [LTHPasscodeViewController sharedUser].delegate = self;
        [LTHPasscodeViewController sharedUser].maxNumberOfAllowedFailedAttempts = 3;
        if ([LTHPasscodeViewController doesPasscodeExist] && [LTHPasscodeViewController didPasscodeTimerEnd]) {
            [[LTHPasscodeViewController sharedUser] showLockScreenWithAnimation:YES
                                                                     withLogout:NO
                                                                 andLogoutTitle:nil];
        } else {
            [JNKeychain deleteValueForKey:PRIV_KEY];
            [JNKeychain deleteValueForKey:PUB_KEY];
            [JNKeychain deleteValueForKey:BITHASH_ID];
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Keys obliterated! Kill and reopen Orthros to create a new account." message:nil preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        }

    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:^(UIAlertAction * __nonnull action) {
        // do nothing
    }];
    [warning addAction:cancelAction];
    [warning addAction:obliterateAction];
    [self presentViewController:warning animated:YES completion:nil];
}

- (void)passcodeWasEnteredSuccessfully {
    if (isObliterating) {
        [JNKeychain deleteValueForKey:PRIV_KEY];
        [JNKeychain deleteValueForKey:PUB_KEY];
        [JNKeychain deleteValueForKey:BITHASH_ID];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Keys obliterated! Kill and reopen Orthros to create a new account." message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

#pragma mark - UITableView functions

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 0) {
        return YES;
    }
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    return (action == @selector(copy:));
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    if (action == @selector(copy:)) {
        UITableViewCell *cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
        [[UIPasteboard generalPasteboard] setString:cell.detailTextLabel.text];
    }
}
@end
