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
}
@property (strong, nonatomic) IBOutlet UITextView *messageBox;
@property (strong, nonatomic) IBOutlet UITextField *recievingIDBox;

@end

@implementation ComposeTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    identify = [[DeviceIdentifiers alloc] init];
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
        [KVNProgress show];
        [KVNProgress showWithStatus:@"Sending"];
        [self sendMessage:self.messageBox.text withUUID:self.recievingIDBox.text];
    } else if ([self isUUID:self.recievingIDBox.text]) {
        [[[UIAlertView alloc] initWithTitle:@"ID is invalid" message:@"Make sure the ID is valid before sending" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil] show];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Oops!" message:@"Looks like one of the fields is unfilled, make sure you've entered in all applicable data" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil] show];
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

-(NSString *)getPubForID:(NSString*)user_id {
    NSString *returnedPub = [[NSString alloc] init];
    NSMutableString *action = Obfuscate.c.a.r.k.m.p.equals.b.m.u.p.j.m.c.b;
    NSString *url = [NSString stringWithFormat:@"%@?%@&UUID=%@&receiver=%@", API_OB, action, [identify UUID], user_id];
    NSData *queryData = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
    if (queryData) {
        NSError *error;
        NSMutableDictionary *responseParsed = [NSJSONSerialization JSONObjectWithData:queryData options:NSJSONReadingMutableContainers error:&error];
        // what the hell
        // cut it up, fix it, put it back together. :) fuck this
        returnedPub = [responseParsed[@"pub"] stringByReplacingOccurrencesOfString:@"-----BEGIN PUBLIC KEY-----" withString:@""];
        returnedPub = [returnedPub stringByReplacingOccurrencesOfString:@"-----END PUBLIC KEY-----" withString:@""];
        if (!returnedPub) {
            return nil;
        }
        returnedPub = [returnedPub stringByReplacingOccurrencesOfString:@" " withString:@"+"];
        returnedPub = [NSString stringWithFormat:@"-----BEGIN PUBLIC KEY-----%@-----END PUBLIC KEY-----", returnedPub];
        if (error)
            NSLog(@"JSON parsing error: %@", error);
    }
    return returnedPub;
}

-(NSString *)getKeyForSend:(NSString*)user_id {
    NSString *returnedKey = [[NSString alloc] init];
    NSMutableString *action = Obfuscate.c.a.r.k.m.p.equals.e.g.p.underscore.i.g.z;
    NSString *url = [NSString stringWithFormat:@"%@?%@&UUID=%@", API_OB, action, [identify UUID]];
    NSData *queryData = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
    BDRSACryptor *RSACryptor = [[BDRSACryptor alloc] init];
    BDError *decError;
    if (queryData) {
        NSError *error;
        NSMutableDictionary *responseParsed = [NSJSONSerialization JSONObjectWithData:queryData options:NSJSONReadingMutableContainers error:&error];
        if (!error)
            returnedKey = [RSACryptor decrypt:responseParsed[@"key"] key:[JNKeychain loadValueForKey:PRIV_KEY] error:decError];
    }
    return returnedKey;
}

-(void)sendMessage:(NSString *)msg withUUID:(NSString *)to_uuid {
    BDRSACryptor *RSACryptor = [[BDRSACryptor alloc] init];
    BDError *error;
    NSString *key = [self getKeyForSend:[identify UUID]];
    if (!key) {
        [KVNProgress showErrorWithStatus:@"Getting one-time send key failed!"];
    }
    NSString *pub = [self getPubForID:to_uuid];
    if (!pub) {
        [KVNProgress showErrorWithStatus:@"User's pub was not found... try again later."];
    } else {
        NSString *cipherText = [RSACryptor encrypt:msg
                                               key:pub
                                             error:error];
        NSDictionary* jsonDict = @{@"sender":[identify UUID],@"msg":cipherText};
        NSData* json = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:nil];
        NSString *jsonStr = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
        NSString *post = [NSString stringWithFormat:@"msg=%@", jsonStr];
        NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
        NSString *postLength = [NSString stringWithFormat:@"%lu",(unsigned long)[postData length]];
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        NSMutableString *action = Obfuscate.c.a.r.k.m.p.equals.q.g.p.b;
        [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?%@&UUID=%@&receiver=%@&key=%@", API_OB, action, [identify UUID], to_uuid, key]]];
        [request setHTTPMethod:@"POST"];
        [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:postData];
        NSURLConnection* connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        if(connection) {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
            NSLog(@"Connection Successful");
        } else {
            NSLog(@"Connection could not be made");
        }
    }
    [KVNProgress dismiss];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData*)data {
    NSError *error;
    NSMutableDictionary *parsedDict = [[NSJSONSerialization JSONObjectWithData:data options:0 error:&error] mutableCopy];
    if (!parsedDict[@"error"] || parsedDict == nil) {
        [KVNProgress showErrorWithStatus:@"Error'd out! Try again." completion:^{ // give better diagnostics when this happens pl0x
            [self.navigationController dismissViewControllerAnimated:YES completion:^{
                [KVNProgress dismiss];
            }];
        }];
    }else {
        [KVNProgress showSuccessWithCompletion:^{
            [self.navigationController dismissViewControllerAnimated:YES completion:^{
                [KVNProgress dismiss];
            }];
        }];
    }
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
