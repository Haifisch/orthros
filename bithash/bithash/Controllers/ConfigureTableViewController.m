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
#import "BDRSACryptor.h"
#import "BDRSACryptorKeyPair.h"
#import "BDError.h"
#import "BDLog.h"
#import "KVNProgress.h"
#import "LTHPasscodeViewController.h"
@interface ConfigureTableViewController () <LTHPasscodeViewControllerDelegate> {
    DeviceIdentifiers *identify;
    BOOL isObliterating;
    liborthros *orthros;
    NSUserDefaults *defaults;
    NSDate *updatedEpoch;
    NSInteger epochHours;
}

@property (strong, nonatomic) IBOutlet UISwitch *passSwitch;
@property (strong, nonatomic) IBOutlet UILabel *uuidLabel;
@property (strong, nonatomic) IBOutlet UILabel *buildLabel;
@property (strong, nonatomic) IBOutlet UITableViewCell *obliterateCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *passcodeCell;
@property (strong, nonatomic) IBOutlet UILabel *versionLabel;
@property (strong, nonatomic) IBOutlet UILabel *keypairAgeLabel;
@property (strong, nonatomic) IBOutlet UIButton *changePasscodeBtn;
@end

@implementation ConfigureTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    defaults = [[NSUserDefaults alloc] initWithSuiteName:@"ninja.orthros.group.suite"];
    self.tableView.backgroundColor = [UIColor colorWithRed:33/255.0f green:33/255.0f blue:33/255.0f alpha:1];
    [self.tableView setSeparatorColor:[UIColor colorWithRed:33/255.0f green:33/255.0f blue:33/255.0f alpha:1]];

    identify = [[DeviceIdentifiers alloc] init];
    if ([JNKeychain loadValueForKey:@"api_endpoint"]) {
        orthros = [[liborthros alloc] initWithAPIAddress:[JNKeychain loadValueForKey:@"api_endpoint"] withUUID:[identify UUID]];
    } else {
        orthros = [[liborthros alloc] initWithUUID:[identify UUID]];
        [orthros setAPIAdress:@"https://api.orthros.ninja"];
    }
    [self.uuidLabel setText:[identify UUID]];
    isObliterating = NO;
    
    self.passSwitch = [[UISwitch alloc] init];
    [self.passSwitch addTarget:self action:@selector(passcodeToggle:) forControlEvents:UIControlEventValueChanged];
    [self.passcodeCell setAccessoryView:self.passSwitch];
    
    NSDictionary *infoDictionary = [[NSBundle mainBundle]infoDictionary];
    NSString *build = infoDictionary[(NSString*)kCFBundleVersionKey];
    self.versionLabel.text = [[NSString alloc] initWithFormat:@"%@ Build #%@", @MAJOR_ORTHROS_VERSION, build];
    updatedEpoch = [orthros userPublicKeyLifetime];
    if (updatedEpoch) {
        NSDate *today = [NSDate date];
        NSUInteger unitFlags = NSCalendarUnitHour | NSCalendarUnitMinute;
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        NSDateComponents *components = [calendar components:unitFlags fromDate:updatedEpoch toDate:today options:0];
        epochHours = [components hour];
        NSInteger minutes = [components minute];
        self.keypairAgeLabel.text = [NSString stringWithFormat:@"%ld hours, %ld minutes", (long)epochHours, (long)minutes];
    } else {
        self.keypairAgeLabel.text = [NSString stringWithFormat:@"N/A"];
    }
    [self checkKeypairAge:nil];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.passSwitch setOnTintColor:orthros_purple];
    if ([LTHPasscodeViewController doesPasscodeExist]) {
        [self.passSwitch setOn:YES animated:YES];
        [self.changePasscodeBtn setEnabled:YES];
        [self.changePasscodeBtn setTitleColor:orthros_purple forState:UIControlStateNormal];
    } else {
        [self.passSwitch setOn:NO animated:YES];
        [self.changePasscodeBtn setEnabled:NO];
        [self.changePasscodeBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)checkKeypairAge:(id)sender {
    if (sender) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Manual keypair renew " message:@"Performing this will obliterate your previous public key from the Orthros backend and the copy on your device then create and submit a newly generated public key. This occurs automatically every 24 hours." preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Renew keys" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            BDError *error = [[BDError alloc] init];
            BDRSACryptor *RSACryptor = [[BDRSACryptor alloc] init];
            dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                BDRSACryptorKeyPair *RSAKeyPair = [RSACryptor generateKeyPairWithKeyIdentifier:@"orthros_pair_popped" error:error];
                NSString *nonce = [orthros genNonce];
                if ([orthros submitNewPublicKey:RSAKeyPair.publicKey withKey:[RSACryptor decrypt:nonce key:[JNKeychain loadValueForKey:PRIV_KEY] error:error]]) {
                    [JNKeychain deleteValueForKey:PRIV_KEY];
                    [JNKeychain deleteValueForKey:PUB_KEY];
                    [JNKeychain saveValue:RSAKeyPair.publicKey forKey:PUB_KEY];
                    [JNKeychain saveValue:RSAKeyPair.privateKey forKey:PRIV_KEY];
                }
            });
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    } else if (epochHours > 24) {
        BDError *error = [[BDError alloc] init];
        BDRSACryptor *RSACryptor = [[BDRSACryptor alloc] init];
        dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            BDRSACryptorKeyPair *RSAKeyPair = [RSACryptor generateKeyPairWithKeyIdentifier:@"orthros_pair_popped" error:error];
            NSString *nonce = [orthros genNonce];
            if ([orthros submitNewPublicKey:RSAKeyPair.publicKey withKey:[RSACryptor decrypt:nonce key:[JNKeychain loadValueForKey:PRIV_KEY] error:error]]) {
                [JNKeychain deleteValueForKey:PRIV_KEY];
                [JNKeychain deleteValueForKey:PUB_KEY];
                [JNKeychain saveValue:RSAKeyPair.publicKey forKey:PUB_KEY];
                [JNKeychain saveValue:RSAKeyPair.privateKey forKey:PRIV_KEY];
            }
        });
    }
}


- (IBAction)done:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)passcodeToggle:(id)sender {
    UISwitch *swch = (UISwitch *)sender;
    if (!swch.isOn) {
        [self.changePasscodeBtn setEnabled:NO];
        [self.changePasscodeBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [defaults setBool:NO forKey:@"pcb"];
        [[LTHPasscodeViewController sharedUser] showForDisablingPasscodeInViewController:self
                                                                                 asModal:YES];
    } else {
        [self.changePasscodeBtn setEnabled:YES];
        [self.changePasscodeBtn setTitleColor:orthros_purple forState:UIControlStateNormal];
        [defaults setBool:YES forKey:@"pcb"];
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
            [self runObliteration];
        }

    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:^(UIAlertAction * __nonnull action) {
        isObliterating = NO;
    }];
    warning.popoverPresentationController.sourceView = self.obliterateCell;
    warning.popoverPresentationController.sourceRect = self.obliterateCell.bounds;
    [warning addAction:cancelAction];
    [warning addAction:obliterateAction];
    [self presentViewController:warning animated:YES completion:nil];
}

- (void)runObliteration {
    BDRSACryptor *RSACryptor = [[BDRSACryptor alloc] init];
    BDError *error;
    NSString *enc_key = [orthros genNonce];
    if ([JNKeychain loadValueForKey:PRIV_KEY] || [JNKeychain loadValueForKey:PUB_KEY]) {
        if (![orthros obliterateWithKey:[RSACryptor decrypt:enc_key key:[JNKeychain loadValueForKey:PRIV_KEY] error:error]]) {
            [KVNProgress showErrorWithStatus:@"Error'd out! Try again." completion:^{}];
            isObliterating = NO;
        }else {
            [KVNProgress dismiss];
        }
    }
    [defaults setBool:NO forKey:@"pcb"];
    [defaults setBool:NO forKey:@"successfulSetup"];
    if ([LTHPasscodeViewController doesPasscodeExist] && [LTHPasscodeViewController didPasscodeTimerEnd]) {
        [LTHPasscodeViewController sharedUser].delegate = self;
        [LTHPasscodeViewController sharedUser].maxNumberOfAllowedFailedAttempts = 3;
        [[LTHPasscodeViewController sharedUser] showForDisablingPasscodeInViewController:self asModal:YES];
    }
    [JNKeychain deleteValueForKey:PRIV_KEY];
    [JNKeychain deleteValueForKey:PUB_KEY];
    [JNKeychain deleteValueForKey:BITHASH_ID];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Obliterate" message:@"Keys obliterated! Kill and reopen Orthros to create a new account." preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}
- (void)passcodeWasEnteredSuccessfully {
    if (isObliterating) {
       [self runObliteration];
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

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [cell setBackgroundColor:[UIColor colorWithRed:72/255.0f green:72/255.0f blue:72/255.0f alpha:1]];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 35;
}

- (CGFloat)tableView:(UITableView*)tableView heightForFooterInSection:(NSInteger)section {
    return 1.0;
}

- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section {
    return [[UIView alloc] initWithFrame:CGRectZero];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(10, 0, 200, 35)];
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:headerView.frame];
    headerLabel.textColor = [UIColor whiteColor];
    headerLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:17];
    switch (section) {
        case 0:
            headerLabel.text = @"Settings";
            break;
            
        case 1:
            headerLabel.text = @"Credits / Support";
            break;
            
        default:
            break;
    }
    [headerView addSubview:headerLabel];
    return headerView;
}
@end
