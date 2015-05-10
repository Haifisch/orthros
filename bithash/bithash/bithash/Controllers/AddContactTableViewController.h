//
//  AddContactTableViewController.h
//  bithash
//
//  Created by Haifisch on 4/14/15.
//  Copyright (c) 2015 Haifisch. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AddContactTableViewController : UITableViewController
@property (nonatomic, assign) BOOL isFromMessage;
@property (nonatomic, assign) NSString *recieving_id;

@end
