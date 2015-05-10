//
//  GenerateRSAViewController.m
//  bithash
//
//  Created by Haifisch on 2/14/15.
//  Copyright (c) 2015 Haifisch. All rights reserved.
//

#import "GenerateRSAViewController.h"
#import "UIAlertView+Blocks.h"
#import "Common.h"

#define HEADER_HEIGHT 120

@interface GenerateRSAViewController ()
@end

@implementation GenerateRSAViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setTitle:@"Generate RSA Keys"];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([JNKeychain loadValueForKey:PRIV_KEY] || [JNKeychain loadValueForKey:PUB_KEY]) {
        [self enableKeyCells:YES];
    }else {
        [self enableKeyCells:NO];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)generateKeys
{
    if ([JNKeychain loadValueForKey:PRIV_KEY] || [JNKeychain loadValueForKey:PUB_KEY]) {
        // Keys already exsist, would you like to overwrite them?
        [UIAlertView showWithTitle:@"Oops!"
                           message:@"Looks like your RSA keys already exsist! Would you like to overwrite them?"
                 cancelButtonTitle:@"Cancel"
                 otherButtonTitles:@[@"Yes"]
                          tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                              if (buttonIndex == [alertView cancelButtonIndex]) {
                                  NSLog(@"Cancelled");
                              } else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Yes"]) {
                                  BDError *error = [[BDError alloc] init];
                                  BDRSACryptor *RSACryptor = [[BDRSACryptor alloc] init];
                                  
                                  BDRSACryptorKeyPair *RSAKeyPair = [RSACryptor generateKeyPairWithKeyIdentifier:@"key_pair_tag"
                                                                                                           error:error];
                                  [JNKeychain saveValue:RSAKeyPair.privateKey forKey:PRIV_KEY];
                                  [JNKeychain saveValue:RSAKeyPair.publicKey forKey:PUB_KEY];
                                  if ([self testEncryptDecryptWithRSACryptor:RSACryptor keyPair:RSAKeyPair error:error]) {
                                      [self enableKeyCells:YES]; // keys were generated and stored.
                                  }
                              }
                          }];
    } else {
        BDError *error = [[BDError alloc] init];
        BDRSACryptor *RSACryptor = [[BDRSACryptor alloc] init];
        
        BDRSACryptorKeyPair *RSAKeyPair = [RSACryptor generateKeyPairWithKeyIdentifier:@"key_pair_tag"
                                                                                 error:error];
        [JNKeychain saveValue:RSAKeyPair.privateKey forKey:PRIV_KEY];
        [JNKeychain saveValue:RSAKeyPair.publicKey forKey:PUB_KEY];
        if ([self testEncryptDecryptWithRSACryptor:RSACryptor keyPair:RSAKeyPair error:error]) {
            [self enableKeyCells:YES]; // keys were generated and stored.
        }
    }
    
}

-(BOOL)testEncryptDecryptWithRSACryptor:(BDRSACryptor *)RSACryptor keyPair:(BDRSACryptorKeyPair *)RSAKeyPair error:(BDError *)error {
    NSString *originalText = [NSString stringWithUTF8String:"Test string encryption"];
    NSString *cipherText = [RSACryptor encrypt:originalText key:RSAKeyPair.publicKey error:error];
    NSString *recoveredText = [RSACryptor decrypt:cipherText key:RSAKeyPair.privateKey error:error];
    if ([BDError errorContainsErrors:error] || recoveredText == NULL) {
        return NO;
    }
    return YES;
}

- (void)importKeysExample
{
    BDError *error = [[BDError alloc] init];
    BDRSACryptor *RSACryptor = [[BDRSACryptor alloc] init];
    
    BDRSACryptorKeyPair *RSAKeyPair = [[BDRSACryptorKeyPair alloc] initWithPublicKey:[JNKeychain loadValueForKey:PUB_KEY]
                                                                          privateKey:[JNKeychain loadValueForKey:PRIV_KEY]];
    
    [self encryptionCycleWithRSACryptor:RSACryptor
                                keyPair:RSAKeyPair
                                  error:error];
}


- (void)encryptionCycleWithRSACryptor:(BDRSACryptor *)RSACryptor
                              keyPair:(BDRSACryptorKeyPair *)RSAKeyPair
                                error:(BDError *)error
{
    NSString *cipherText =
    [RSACryptor encrypt:@"Plain Text"
                    key:RSAKeyPair.publicKey
                  error:error];
    
    BDDebugLog(@"Cipher Text:\n%@", cipherText);
    
    NSString *recoveredText =
    [RSACryptor decrypt:cipherText
                    key:RSAKeyPair.privateKey
                  error:error];
    
    BDDebugLog(@"Recovered Text:\n%@", recoveredText);
}

#pragma mark - Table view
-(void)enableKeyCells:(BOOL)enabled {
    // Change cell appearance to look disabled by default.
    UITableViewCell *keyCell = (UITableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    UITableViewCell *nextCell = (UITableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];

    [UIView animateWithDuration:0.3f
                     animations:^{
                         if (!enabled) {
                             keyCell.alpha = 0.2;
                             nextCell.alpha = 0.2;
                         }else {
                             keyCell.alpha = 1.0;
                             nextCell.alpha = 1.0;
                         }
                         keyCell.userInteractionEnabled = enabled;
                         keyCell.textLabel.enabled = enabled;
                         keyCell.detailTextLabel.enabled = enabled;
                         nextCell.userInteractionEnabled = enabled;
                         nextCell.textLabel.enabled = enabled;
                         nextCell.detailTextLabel.enabled = enabled;
                     }
    ];
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, HEADER_HEIGHT)];
        UILabel *rsaLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, headerView.bounds.size.width - 20, headerView.bounds.size.height)];
        rsaLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
        rsaLabel.text = @"This is where we will generate our RSA keys, both a public key and a private key. The public key is shared and stored on our servers for peer download use to encrypt messages so that only you can decrypt with your private key, the private key is stored in the iOS keychain, which is then encrypted with your phone's passcode using AES as the cryptography engine."; // we should have this localized.
        rsaLabel.adjustsFontSizeToFitWidth = YES;
        [rsaLabel setNumberOfLines:6];
        rsaLabel.textAlignment = NSTextAlignmentCenter;
        [headerView addSubview:rsaLabel];
        return headerView;
    }else {
        return nil;
    }
}

-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return HEADER_HEIGHT;
    }
    return UITableViewAutomaticDimension;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return HEADER_HEIGHT;
    }
    return UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0 && indexPath.row == 0) {
        [self generateKeys];
    }else if (indexPath.section == 0 && indexPath.row == 1) {
        [self performSegueWithIdentifier:@"PreviewKeys" sender:self];
    }else if (indexPath.section == 1 && indexPath.row == 0) {
        [self performSegueWithIdentifier:@"BeginUpload" sender:self];
    }
}

@end
