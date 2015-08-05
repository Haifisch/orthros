//
//  ScanQRViewController.h
//  Orthros
//
//  Created by Haifisch on 5/18/15.
//  Copyright (c) 2015 Haifisch. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AddContactTableViewController.h"
@interface ScanQRViewController : UIViewController
@property (nonatomic, assign) id <AddContactDelegate> delegate;
@end
