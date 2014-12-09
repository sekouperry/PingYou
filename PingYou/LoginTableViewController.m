//
//  LoginTableViewController.m
//  PingYou
//
//  Created by André Hansson on 15/10/14.
//  Copyright (c) 2014 PingPal AB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LoginTableViewController.h"
#import "DataStore.h"
#import "ContactsTableViewController.h"
#import <PPLocationManager/Outbox.h>
#import <PPLocationManager/PPLocationManager.h>

@interface LoginTableViewController (){
    BOOL availableNicknameEntered;
}

@property (weak, nonatomic) IBOutlet UITextView *nicknameTextView;

@property (weak, nonatomic) IBOutlet UILabel *nicknameLabel;

@property (weak, nonatomic) IBOutlet UITableViewCell *availabilityCell;

@property (weak, nonatomic) IBOutlet UILabel *availabilityLabel;

@end

@implementation LoginTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor colorWithRed:0.282 green:0.733 blue:0.565 alpha:1.000]];
    
    NSString *deviceTag = [DataStore deviceTag];
    NSString *aliasTag = [DataStore aliasTag];
    NSLog(@"deviceTag: %@", deviceTag);
    NSLog(@" aliasTag: %@", aliasTag);
    
    // If the user is registered we skip to the ContactsTableViewController.
    if (aliasTag && deviceTag)
    {
        // Already registered
        
        [self startWithDevice:deviceTag andAlias:aliasTag];
        
        [self showContactsAnimated:NO];
    }
    
    availableNicknameEntered = NO;
}


#pragma mark - UITextView Delegate

-(void)textViewDidChange:(UITextView *)textView
{
    if ([textView.text length])
    {
        // There is text
        
        [_nicknameLabel setHidden:YES];
        
        if ([textView.text length] == 1)
        {
            // A tag needs to be at least two characters long
            [_availabilityCell setBackgroundColor:[UIColor redColor]];
            [_availabilityLabel setText:@"TOO SHORT"];
            availableNicknameEntered = NO;
        }
        else
        {
            // Check if the tag is already registered
            [Outbox tagExists:[NSString stringWithFormat:@"#%@", [textView.text lowercaseString]] withCallback:^(NSError *error, BOOL exists) {
                
                if (exists)
                {
                    // Nickname taken
                    [_availabilityCell setBackgroundColor:[UIColor redColor]];
                    [_availabilityLabel setText:@"UNAVAILABLE"];
                    availableNicknameEntered = NO;
                }
                else
                {
                    // Nickname free
                    [_availabilityCell setBackgroundColor:[UIColor greenColor]];
                    [_availabilityLabel setText:@"AVAILABLE"];
                    availableNicknameEntered = YES;
                }
            }];
        }
    }
    else
    {
        // There is no text
        [_nicknameLabel setHidden:NO];
        [_availabilityLabel setText:@""];
        availableNicknameEntered = NO;
    }
}

- (BOOL) textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    // If the user clicks on done. Close the keyboard. Do not allow linebreaks.
    if ([text isEqualToString:@"\n"])
    {
        [textView resignFirstResponder];
        return NO;
    }
    return YES;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 4;
}


#pragma mark - Table view delegate

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 80;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row)
    {
        case 2: // NEXT
            // If the user has entered an available nickname we register them and open the ContactsTableViewController.
            if (availableNicknameEntered)
            {
                [self registerNickname];
                
                [_nicknameTextView resignFirstResponder];
                
                [self showContactsAnimated:YES];
            }
            break;
        
        case 3: // EULA
            
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://pingyou.apptimate.io/eula.html"]];
            
            break;
            
        default:
            break;
    }
}


#pragma mark - Register/Login

-(void)registerNickname
{
    // Create the nessesary tags
    NSString *deviceTag = [Outbox createUniqueTag];
    NSString *aliasTag = [[NSString stringWithFormat:@"#%@", _nicknameTextView.text]lowercaseString];
    
    // Save the tags
    [DataStore setDeviceTag:deviceTag];
    [DataStore setAliasTag:aliasTag];
    
    // Start Outbox
    [self startWithDevice:deviceTag andAlias:aliasTag];
}

-(void)startWithDevice:(NSString*)deviceTag andAlias:(NSString*)aliasTag
{
    NSLog(@"startWithDevice:%@ andAlias:%@", deviceTag, aliasTag);
    
    [Outbox startWithTag:deviceTag andAlias:aliasTag andCallback:^(NSError *error) {
        if (error) {
            NSLog(@"Outbox startWithTagandAlias error: %@", error);
        }else{
            NSLog(@"Outbox started");
            
            [self registerPush];
            
            // Create the push that will be used when answering pings.
            NSDictionary *push = @{@"mode": @"fallback",
                                   @"apns": @{
                                           @"message":@0,
                                           @"expire":@604800,
                                           @"data":@{
                                                   @"aps": @{
                                                           @"alert":[NSString stringWithFormat:@"Ping answer from %@", [[DataStore aliasTag] substringFromIndex:1]],
                                                           @"sound":@"default"
                                                           },
                                                   }
                                           }
                                   };
            
            // Set the answer push
            [PPLocationManager answerDevicePositionWithPush:push];
        }
    }];
}

-(void)registerPush
{
    if (![DataStore isPushRegistered])
    {
        NSLog(@"Registering push");
        
        if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)])
        {
            UIUserNotificationType type = UIUserNotificationTypeBadge|UIUserNotificationTypeSound|UIUserNotificationTypeAlert;
            
            UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:type categories:nil];
            
            [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
            
            [[UIApplication sharedApplication] registerForRemoteNotifications];
        }
        else
        {
            [[UIApplication sharedApplication] registerForRemoteNotificationTypes: (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
        }
    }
}


#pragma mark - Open Contacts view

-(void)showContactsAnimated:(BOOL)animated
{
    NSLog(@"showContactsAnimated: %@", animated ? @"YES":@"NO");
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];

    ContactsTableViewController *contacts = [storyboard instantiateViewControllerWithIdentifier:@"Contacts"];
    
    [self addChildViewController:contacts];
    
    if (animated) {
        CATransition *transition = [CATransition animation];
        transition.duration = 0.5;
        transition.type = kCATransitionPush;
        transition.subtype = kCATransitionFromRight;
        [transition setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
        [self.view.layer addAnimation:transition forKey:nil];
    }
    
    [self.view addSubview:contacts.view];
}

-(void)closeContacts
{
    for (UIViewController *vc in [[self childViewControllers]copy])
    {
        if ([vc isKindOfClass:[ContactsTableViewController class]])
        {
            [vc removeFromParentViewController];
            [vc.view removeFromSuperview];
        }
    }
}


@end