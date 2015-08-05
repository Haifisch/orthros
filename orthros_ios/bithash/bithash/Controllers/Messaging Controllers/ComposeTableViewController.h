//
//  ComposeTableViewController.h
//  bithash
//
//  Created by Haifisch on 4/6/15.
//  Copyright (c) 2015 Haifisch. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ComposeTableViewController : UITableViewController <UITextViewDelegate>
@property (nonatomic, assign) BOOL isReply;
@property (nonatomic, assign) BOOL fromContactsOrURL;
@property (nonatomic, assign) NSString *reply_id;

@end
