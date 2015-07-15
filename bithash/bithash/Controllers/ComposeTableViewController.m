//
//  ComposeTableViewController.m
//  bithash
//
//  Created by Haifisch on 4/6/15.
//  Copyright (c) 2015 Haifisch. All rights reserved.
//

#import "ComposeTableViewController.h"
#import "JNKeychain.h"
#import "DeviceIdentifiers.h"
#import "KVNProgress.h"
#import <BDRSACryptor.h>
#import "Common.h"

@interface ComposeTableViewController (){
    DeviceIdentifiers *identify;
    liborthros *orthros;
}
@property (strong, nonatomic) IBOutlet UITextView *messageBox;
@property (strong, nonatomic) IBOutlet UITextField *recievingIDBox;
@property (strong, nonatomic) IBOutlet UILabel *counterLabel;

@end

@implementation ComposeTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    identify = [[DeviceIdentifiers alloc] init];
    orthros = [[liborthros alloc] initWithUUID:[identify UUID]];
    self.title = @"New Message";
    if (self.isReply) {
        [self.recievingIDBox setEnabled:NO];
        [self.recievingIDBox setText:self.reply_id];
        [self.messageBox becomeFirstResponder];
        self.title = @"Reply";
    } else if (self.fromContactsOrURL) {
        [self.recievingIDBox setEnabled:NO];
        [self.recievingIDBox setText:self.reply_id];
        [self.messageBox becomeFirstResponder];
    } else {
        [self.recievingIDBox becomeFirstResponder];
    }
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)attemptSending:(id)sender {
    if ([self.messageBox.text length] > 0 && [self.recievingIDBox.text length] > 0) {
        [KVNProgress showWithStatus:@"Sending"];
        [self sendMessage:self.messageBox.text withUUID:self.recievingIDBox.text];
    } else if ([self isUUID:self.recievingIDBox.text]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"ID is invalid" message:@"Make sure the ID is valid before sending" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {}];
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Oops!" message:@"Looks like one of the fields is unfilled, make sure you've entered in all applicable data" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {}];
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (BOOL)isUUID:(NSString *)inputStr
{
    BOOL isUUID = FALSE;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\A\\{[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}\\}\\Z" options:NSRegularExpressionCaseInsensitive error:nil];
    NSInteger matches = [regex numberOfMatchesInString:inputStr options:0 range:NSMakeRange(0, [inputStr length])];
    if (matches == 1) {
        isUUID = TRUE;
    }
    return isUUID;
}

-(void)sendMessage:(NSString *)msg withUUID:(NSString *)to_uuid {
    BDRSACryptor *RSACryptor = [[BDRSACryptor alloc] init];
    NSString *pub = [orthros publicKeyFor:to_uuid];
    if (!pub) {
        [KVNProgress showErrorWithStatus:@"User's pub was not found... try again later."];
    } else {
        BDError *error;
        NSString *cipherText = [RSACryptor encrypt:msg
                                               key:pub
                                             error:error];
        if (!cipherText) {
            [KVNProgress showErrorWithStatus:@"Error'd out! Try again." completion:^{}];
        } else {
            NSString *enc_key = [orthros genNonce];
            if (![orthros send:cipherText toUser:to_uuid withKey:[RSACryptor decrypt:enc_key key:[JNKeychain loadValueForKey:PRIV_KEY] error:nil]]) {
                [KVNProgress showErrorWithStatus:@"Error'd out! Try again." completion:^{ // give better diagnostics when this happens pl0x
                    [self.navigationController dismissViewControllerAnimated:YES completion:^{
                        [KVNProgress dismiss];
                    }];
                    
                }];
            }else {
                [self.navigationController dismissViewControllerAnimated:YES completion:^{
                    [KVNProgress showSuccess];
                }];
            }
        }
    }
    [KVNProgress dismiss];
}

- (IBAction)cancelCompose:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    
    NSLog(@"connectionFailed: %@", error.localizedDescription);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSInteger textlength = [textView.text length] - range.length + [text length];
    if (textlength > 383) {
        return NO;
    }
    self.counterLabel.text = [NSString stringWithFormat:@"%li/383", (long)textlength];
    return YES;
}

/* NEED SSL ON SERVER FIRST
- (BOOL)shouldTrustProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    // Load up the bundled certificate.
    NSString *certPath = [[NSBundle mainBundle] pathForResource:@"cert" ofType:@"der"];
    NSData *certData = [[NSData alloc] initWithContentsOfFile:certPath];
    CFDataRef certDataRef = (__bridge_retained CFDataRef)certData;
    SecCertificateRef cert = SecCertificateCreateWithData(NULL, certDataRef);
    
    // Establish a chain of trust anchored on our bundled certificate.
    CFArrayRef certArrayRef = CFArrayCreate(NULL, (void *)&cert, 1, NULL);
    SecTrustRef serverTrust = protectionSpace.serverTrust;
    SecTrustSetAnchorCertificates(serverTrust, certArrayRef);
    
    // Verify that trust.
    SecTrustResultType trustResult;
    SecTrustEvaluate(serverTrust, &trustResult);
    
    // Clean up.
    CFRelease(certArrayRef);
    CFRelease(cert);
    CFRelease(certDataRef);
    
    // Did our custom trust chain evaluate successfully?
    return trustResult == kSecTrustResultUnspecified;
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    if ([self shouldTrustProtectionSpace:challenge.protectionSpace]) {
        [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
    } else {
        [challenge.sender performDefaultHandlingForAuthenticationChallenge:challenge];
    }
}
*/
@end
