//
//  ContactsTableViewController.m
//  PingYou
//
//  Created by André Hansson on 15/10/14.
//  Copyright (c) 2014 PingPal AB. All rights reserved.
//

#import "ContactsTableViewController.h"
#import "CoreDataWrapper.h"
#import "Contact.h"
#import "MapViewController.h"
#import "DataStore.h"
#import "ContactCell.h"

#import <PPLocationManager/Outbox.h>
#import <PPLocationManager/PPLocationManager.h>

#define FirstContactString @"Swipe to the left on the contact to reveal some options.\n\nSelect yes or no to decide if you want that person to be able to get your location or not.\n\nSwipe to the right to reveal the report button. You can report users with inappropriate nicknames."

@interface ContactsTableViewController (){
    NSMutableArray *contacts;
    NSMutableArray *optionCells;
    
    UILabel *addContactLabel;
    
    UILabel *restoreCellLabel;
    BOOL restoreSection;
    NSMutableArray *deletedContacts;
    
    Inbox newContactInbox;
}

@end

@implementation ContactsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor colorWithRed:0.282 green:0.733 blue:0.565 alpha:1.000]];
    
    restoreSection = NO;
    
    // Contacts
    contacts = [[NSMutableArray alloc]init];
    [contacts addObjectsFromArray:[CoreDataWrapper fetchContacts]];
    
    // Options
    optionCells = [[NSMutableArray alloc]initWithObjects:@"addContactCell", nil];
    
    // If there are any deleted contacts add the restore cell.
    if ([[CoreDataWrapper fetchDeletedContacts] count] != 0) {
        [optionCells addObject:@"restoreCell"];
    }
    
    // Create a weak reference to self that we will use in the newContactInbox block to avoid a retain cycle
    __weak typeof(self) weakSelf = self;
    
    // Inbox for new contact
    newContactInbox = ^(NSMutableDictionary *payload, NSMutableDictionary *options, Outbox *outbox){
        NSLog(@"newContactInbox - Payload: %@. Options: %@", payload, options);
        
        // Make a strong reference to the weak reference. This will make sure the weak reference isn't released before the end of the block
        __strong typeof(self) strongSelf = weakSelf;

        // Make sure strongSelf exists
        if (strongSelf)
        {
            NSString *nickname = payload[@"newFriend"];
            
            // Check to see that we don't already have this contact
            if (![CoreDataWrapper fetchContactWithNickname:nickname])
            {
                NSLog(@"newContactInbox - New contact added: %@", nickname);
                
                // Create the contact and reload the tableView
                [CoreDataWrapper createNewContact:nickname];
                [strongSelf reloadContacts];
                
                // If this is our first contact we show a tip about how to approve contacts to ping
                if (![DataStore hasShownFirstContactTips])
                {
                    [[[UIAlertView alloc]initWithTitle:[FirstContactString uppercaseString] message:nil delegate:strongSelf cancelButtonTitle:@"OK" otherButtonTitles: nil]show];
                    [DataStore setHasShownFirstContactTips:YES];
                }
            }
        }
    };
    [Outbox attachInbox:newContactInbox withPredicate:[NSPredicate predicateWithFormat:@"payload.newFriend != nil"]];
}

-(void)reloadContacts
{
    [contacts removeAllObjects];
    
    [contacts addObjectsFromArray:[CoreDataWrapper fetchContacts]];
    
    [self.tableView reloadData];
}

-(void)reloadDeletedContacts
{
    [deletedContacts removeAllObjects];
    
    [deletedContacts addObjectsFromArray:[CoreDataWrapper fetchDeletedContacts]];
    
    // If there are no deleted contacts we remove the restore cell.
    if (deletedContacts.count == 0 && [optionCells containsObject:@"restoreCell"]) {
        restoreSection = NO;
        [restoreCellLabel setText:@"RESTORE"];
        [optionCells removeObject:@"restoreCell"];
    }
    
    [self.tableView reloadData];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    if (restoreSection) {
        return 3;
    }else{
        return 2;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    switch (section){
        case 0:
            return contacts.count;
            break;
        case 1:
            return optionCells.count;
            break;
        case 2:
            return deletedContacts.count;
            break;
        default:
            return 0;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) // Contacts
    {
        static NSString *cellIdentifier = @"contactCell";
        
        ContactCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        
        // SWTableViewCell
        cell.rightUtilityButtons = [self rightButtons];
        cell.leftUtilityButtons = [self leftButtons];
        cell.delegate = self;
        
        // Set the name
        [cell.nameLabel setText: [[(Contact*)[contacts objectAtIndex:indexPath.row]nickname]uppercaseString] ];
        
        // Change the color of the cell depending on the contacts state (yes = green, no = red)
        if ([(Contact*)[contacts objectAtIndex:indexPath.row]state] == stateYes)
        {
            [cell setBackgroundColor:[UIColor colorWithRed:0.021 green:0.950 blue:0.032 alpha:1.000]];
        }
        else
        {
            [cell setBackgroundColor:[UIColor redColor]];
        }
        
        return cell;
    }
    else if (indexPath.section == 1) // Options (add contact and restore)
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[optionCells objectAtIndex:indexPath.row] forIndexPath:indexPath];
        
        // We need a reference to the labels in the cells to be able to change them in other places.
        if ([[optionCells objectAtIndex:indexPath.row] isEqualToString:@"addContactCell"]) {
            addContactLabel = (UILabel*)[cell viewWithTag:100];
        }else{
            restoreCellLabel = (UILabel*)[cell viewWithTag:100];
        }
        
        return cell;
    }
    else // Restore section (deleted cotacts)
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"deletedContactCell" forIndexPath:indexPath];
        
        UILabel *nameLabel = (UILabel*)[cell viewWithTag:100];
        [nameLabel setText: [[(Contact*)[deletedContacts objectAtIndex:indexPath.row]nickname]uppercaseString]];
        
        return cell;
    }
}

- (NSArray *)rightButtons
{
    // Create the buttons that will appear when we swipe on the cell
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    [rightUtilityButtons sw_addUtilityButtonWithColor:[UIColor greenColor]
                                                title:@"YES"];
    
    [rightUtilityButtons sw_addUtilityButtonWithColor:[UIColor redColor]
                                                title:@"NO"];
    
    [rightUtilityButtons sw_addUtilityButtonWithColor:[UIColor purpleColor]
                                                title:@"REMOVE"];
    
    return rightUtilityButtons;
}

-(NSArray*)leftButtons
{
    // Create the buttons that will appear when we swipe on the cell
    NSMutableArray *leftUtilityButtons = [NSMutableArray new];
    [leftUtilityButtons sw_addUtilityButtonWithColor:[UIColor purpleColor]
                                                title:@"REPORT"];
    return leftUtilityButtons;
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index
{
    switch (index)
    {
        case 0:{
            NSLog(@"Yes button was pressed");
            
            // Get the index path of the cell. We use this to get the contact
            NSIndexPath *cellIndexPath = [self.tableView indexPathForCell:cell];
            
            // Set the state on the contact
            [CoreDataWrapper setState:stateYes onContact:[contacts objectAtIndex:cellIndexPath.row]];
            
            // Hide the buttons on the cell
            [cell hideUtilityButtonsAnimated:YES];
            
            // Reload the tableView to show the contacts new color
            [self.tableView reloadData];
        }
            break;
        case 1:{
            NSLog(@"No button was pressed");
            
            // Get the index path of the cell. We use this to get the contact
            NSIndexPath *cellIndexPath = [self.tableView indexPathForCell:cell];
            
            // Set the state on the contact
            [CoreDataWrapper setState:stateNo onContact:[contacts objectAtIndex:cellIndexPath.row]];
            
            // Hide the buttons on the cell
            [cell hideUtilityButtonsAnimated:YES];
            
            // Reload the tableView to show the contacts new color
            [self.tableView reloadData];
        }
            break;
        case 2:{
            NSLog(@"Remove button was pressed");
            
            // Get the index path of the cell. We use this to get the contact
            NSIndexPath *cellIndexPath = [self.tableView indexPathForCell:cell];
            
            // Set the state on the contact
            [CoreDataWrapper setState:stateDeleted onContact:[contacts objectAtIndex:cellIndexPath.row]];
            
            // We remove the contact from the array of contacts
            [contacts removeObjectAtIndex:cellIndexPath.row];
            
            // And we remove it from the tableView with an animation
            [self.tableView deleteRowsAtIndexPaths:@[cellIndexPath]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
            
            // Now that we deleted a contact we can add the restore cell if it's not already added
            if (![optionCells containsObject:@"restoreCell"]) {
                [optionCells addObject:@"restoreCell"];
                [self.tableView reloadData];
            }
        }
            break;
        default:
            break;
    }
}

-(void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerLeftUtilityButtonWithIndex:(NSInteger)index
{
    // Sends a message to the mod about unappropriate nickname
    // In order to not get spammed with reports the report function does not send anything in the github code
    
//    NSIndexPath *cellIndexPath = [self.tableView indexPathForCell:cell];
//    NSString *reportedTag = [NSString stringWithFormat:@"#%@", [(Contact*)[contacts objectAtIndex:cellIndexPath.row]nickname]];
//    
//    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//    [formatter setDateFormat: @"yyyy-MM-dd HH:mm"];
//    
//    //Optionally for time zone conversions
//    [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"CET"]];
//    
//    NSString *dateString = [formatter stringFromDate:[NSDate date]];
//    
//    NSLog(@"dateString: %@", dateString);
//    
//    NSDictionary *push = @{@"mode": @"fallback",
//                           @"apns": @{
//                                   @"message":@0,
//                                   @"expire":@604800,
//                                   @"data":@{
//                                           @"aps": @{
//                                                   @"alert":@"New report",
//                                                   @"sound":@"default"
//                                                   },
//                                           }
//                                   }
//                           };
    
    //[Outbox put:@"#mod" withPayload:@{@"report":reportedTag, @"reportDate":dateString} andOptions:@{@"push":push}];
    NSLog(@"The report function has been disabled for the GitHub code");
    
    // Hide the buttons on the cell
    [cell hideUtilityButtonsAnimated:YES];
}


#pragma mark - UITableView Delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        // Open the mapView with the selected contact.
        
        Contact *selectedContact = [contacts objectAtIndex:indexPath.row];
        NSLog(@"Contact selected: %@", [NSString stringWithFormat:@"#%@", selectedContact.nickname]);
        
        [self openMapViewWithName:[selectedContact nickname]];
        
        // Set lastActive on the contact to now. The contacts are sorted by lastActive
        [CoreDataWrapper setLastActive:[NSDate date] onContact:selectedContact];
        [self reloadContacts];
    }
    else if (indexPath.section == 1)
    {
        if (indexPath.row == 1)
        {
            NSLog(@"Restore");
            // Open and close the restore section.
            
            if (!restoreSection)
            {
                // Show restore
                restoreSection = YES;
                
                [restoreCellLabel setText:@"CLOSE RESTORE"];
                
                if (!deletedContacts) {
                    deletedContacts = [[NSMutableArray alloc]init];
                }
                
                [self reloadDeletedContacts];
            }
            else
            {
                // Hide restore
                restoreSection = NO;
                
                [restoreCellLabel setText:@"RESTORE"];
                
                [self.tableView reloadData];
            }
        }
    }
    else if (indexPath.section == 2)
    {
        // Restore a deleted contact
        Contact *selectedContact = [deletedContacts objectAtIndex:indexPath.row];
        NSLog(@"Deleted contact selected: %@", [selectedContact nickname]);
        
        // Remove the contact from deletedContacts and from the tableView.
        [deletedContacts removeObjectAtIndex:indexPath.row];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
        
        // Set the contacts state to no
        [CoreDataWrapper setState:stateNo onContact:selectedContact];
        
        // Reload both contacts and deletedContacts
        [self reloadContacts];
        [self reloadDeletedContacts];
    }
}


#pragma mark - UITextView Delegate

-(void)textViewDidChange:(UITextView *)textView
{
    if ([textView.text length])
    {
        [addContactLabel setHidden:YES];
    }
    else
    {
        [addContactLabel setHidden:NO];
    }
}

- (BOOL) textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@"\n"]) // When the user clicks on done on the keyboard
    {
        // Get the text from the taxtView in lowercase
        NSString *nickname = [textView.text lowercaseString];
        
        if (nickname.length)
        {
            // There is text
            
            if (nickname.length == 1)
            {
                // A tag needs to be at least two characters long
                NSLog(@"Too short");
                [textView resignFirstResponder];
                [textView setText:@""];
                [addContactLabel setHidden:NO];
                [[[UIAlertView alloc]initWithTitle:@"TOO SHORT" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil]show];
                return NO;
            }
            
            // Check if we already have the contact 
            if ([CoreDataWrapper fetchContactWithNickname:nickname])
            {
                NSLog(@"Contact already added");
                [textView resignFirstResponder];
                [textView setText:@""];
                [addContactLabel setHidden:NO];
                return NO;
            }
            
            // Check if the tag exists on the server
            [Outbox tagExists:[NSString stringWithFormat:@"#%@", nickname] withCallback:^(NSError *error, BOOL exists) {
                if (exists)
                {
                    // Add the contact and reload the contacts
                    [CoreDataWrapper createNewContact:nickname];
                    [self reloadContacts];
                    
                    // Send a message with our nickname to the new contact to let it know that we added it
                    NSString *myNickname = [[DataStore aliasTag] substringFromIndex:1];
                    
                    NSDictionary *push = @{@"mode": @"fallback",
                                           @"apns": @{
                                                   @"message":@0,
                                                   @"expire":@604800,
                                                   @"data":@{
                                                           @"aps": @{
                                                                   @"alert":[NSString stringWithFormat:@"New friend: %@", myNickname],
                                                                   @"sound":@"default"
                                                                   },
                                                           }
                                                   }
                                           };
                    
                    [Outbox put:[NSString stringWithFormat:@"#%@", nickname] withPayload:@{@"newFriend":myNickname} andOptions:@{@"push":push}];
                    
                    // If this is our first contact we show a tip about how to approve contacts to ping
                    if (![DataStore hasShownFirstContactTips])
                    {
                        [[[UIAlertView alloc]initWithTitle:[FirstContactString uppercaseString] message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil]show];
                        [DataStore setHasShownFirstContactTips:YES];
                    }
                }
                else
                {
                    // The tag does not exist
                    
                    [[[UIAlertView alloc]initWithTitle:@"USER DOES NOT EXIST" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil]show];
                }
            }];
            
            [textView resignFirstResponder];
            [textView setText:@""];
            [addContactLabel setHidden:NO];
            return NO;
        }
        else
        {
            // There is no text
            [textView resignFirstResponder];
            return NO;
        }
    }
    return YES;
}

-(void)openMapViewWithName:(NSString*)name
{
    // Create the mapView and set the name
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    MapViewController *mapViewController = [storyboard instantiateViewControllerWithIdentifier:@"Map"];
    
    [mapViewController setName:[name uppercaseString]];

    // Create the push for the ping
    NSDictionary *push = @{@"mode": @"fallback",
                           @"apns": @{
                                   @"message":@0,
                                   @"expire":@604800,
                                   @"data":@{
                                           @"aps": @{
                                                   @"alert":[NSString stringWithFormat:@"Ping from %@", [[DataStore aliasTag] substringFromIndex:1]],
                                                   @"sound":@"default",
                                                   @"content-available":@1
                                                   },
                                           }
                                   }
                           };
    
    // Send the ping with the mapViews pingInbox as the inbox for the response
    [PPLocationManager getDevicePosition:[NSString stringWithFormat:@"#%@", name] withAccuracy:300 andTimeout:30 AndInbox:mapViewController.pingInbox AndOptions:@{@"push":push}];
    
    // Show the mapView
    [self presentViewController:mapViewController animated:YES completion:nil];
}

@end
