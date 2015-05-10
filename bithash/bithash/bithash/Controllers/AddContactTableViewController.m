//
//  AddContactTableViewController.m
//  bithash
//
//  Created by Haifisch on 4/14/15.
//  Copyright (c) 2015 Haifisch. All rights reserved.
//

#import "AddContactTableViewController.h"
#import "KVNProgress.h"
@interface AddContactTableViewController ()
@property (strong, nonatomic) IBOutlet UITextField *recievingID;
@property (strong, nonatomic) IBOutlet UITextField *contactName;

@end

@implementation AddContactTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.isFromMessage) {
        [self.recievingID setEnabled:NO];
        [self.recievingID setText:self.recieving_id];
        [self.contactName becomeFirstResponder];
    } else {
        [self.recievingID becomeFirstResponder];
    }
    self.title = @"Add to contacts";
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addToContacts:)];
    [self.navigationItem setRightBarButtonItem:addButton];
    
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleDone target:self action:@selector(cancel:)];
    [self.navigationItem setLeftBarButtonItem:cancel];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (IBAction)addToContacts:(id)sender {
    UIAlertView *contactFound;

    if (!([self.contactName.text length] > 0 || [self.recievingID.text length] > 0)) {
        [[[UIAlertView alloc] initWithTitle:@"Oops!" message:@"Looks like you've missed a field, check the fields and try again." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil] show];
    }
    NSMutableArray *currentContacts = [[[NSUserDefaults standardUserDefaults] objectForKey:@"contacts"] mutableCopy];
    if (!currentContacts || [currentContacts count] <= 0) {
        currentContacts = [[NSMutableArray alloc] init];
        [currentContacts addObject:[[NSDictionary alloc] initWithObjects:[[NSArray alloc] initWithObjects:self.contactName.text, nil] forKeys:[[NSArray alloc] initWithObjects:self.recievingID.text, nil]]];
        [[NSUserDefaults standardUserDefaults] setObject:currentContacts forKey:@"contacts"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [KVNProgress showSuccessWithStatus:@"Added to contacts!" completion:^{
            [self.navigationController dismissViewControllerAnimated:YES completion:^{
                [KVNProgress dismiss];
            }];
        }];
    } else {
        for (int count; count < [currentContacts count]; count++) {
            if ([currentContacts[count] objectForKey:self.recievingID.text]) {
                if (!contactFound) {
                    contactFound = [[UIAlertView alloc] initWithTitle:@"Oops!" message:@"This contact already exsists." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                    [contactFound show];
                }
            } else {
                [currentContacts addObject:[[NSDictionary alloc] initWithObjects:[[NSArray alloc] initWithObjects:self.contactName.text, nil] forKeys:[[NSArray alloc] initWithObjects:self.recievingID.text, nil]]];
                [[NSUserDefaults standardUserDefaults] setObject:currentContacts forKey:@"contacts"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [KVNProgress showSuccessWithStatus:@"Added to contacts!" completion:^{
                    [self.navigationController dismissViewControllerAnimated:YES completion:^{
                        [KVNProgress dismiss];
                    }];
                }];
            }
        }
    }

}

- (IBAction)cancel:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
