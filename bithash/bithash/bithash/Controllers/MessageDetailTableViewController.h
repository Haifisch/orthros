//
//  MessageDetailTableViewController.h
//  bithash
//
//  Created by Haifisch on 4/12/15.
//  Copyright (c) 2015 Haifisch. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MessageDetailTableViewController : UITableViewController
@property (strong, nonatomic) IBOutlet UILabel *fromLabel;
@property (nonatomic, strong) NSString *sender;
@property (nonatomic, strong) NSString *message;
@property (nonatomic, assign) NSInteger msg_id;

@end
