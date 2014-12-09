//
//  MapViewController.h
//  PingYou
//
//  Created by André Hansson on 15/10/14.
//  Copyright (c) 2014 PingPal AB. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <PPLocationManager/PPLocationManager.h>

@interface MapViewController : UIViewController

@property NSString *name;

@property (nonatomic, copy) Inbox pingInbox;

@end