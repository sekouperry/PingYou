//
//  CoreDataWrapper.m
//  PingYou
//
//  Created by André Hansson on 18/10/14.
//  Copyright (c) 2014 PingPal AB. All rights reserved.
//

#import "CoreDataWrapper.h"
#import "AppDelegate.h"

@implementation CoreDataWrapper

+(NSArray *)fetchContacts
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Contact" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"state != %d", stateDeleted];
    [fetchRequest setPredicate:predicate];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]initWithKey:@"lastActive" ascending:NO];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects == nil) {
        // Handle the error
        NSLog(@"ERROR: %@", error);
    }
    
    return fetchedObjects;
}

+(NSArray *)fetchDeletedContacts
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Contact" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"state == %d", stateDeleted];
    [fetchRequest setPredicate:predicate];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]initWithKey:@"nickname" ascending:YES];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects == nil) {
        // Handle the error
        NSLog(@"ERROR: %@", error);
    }
    
    return fetchedObjects;
}

+(Contact *)fetchContactWithNickname:(NSString *)nickname
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Contact" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"nickname == %@", nickname];
    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects == nil) {
        // Handle the error
        NSLog(@"ERROR: %@", error);
    }
    
    if (fetchedObjects.count == 0) {
        NSLog(@"fetchContactWithNickname - no contact with nickname: %@", nickname);
        return NULL;
    }
    
    return [fetchedObjects objectAtIndex:0];
}


+(Contact*)createNewContact:(NSString *)nickname
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    
    Contact *newContact = [NSEntityDescription insertNewObjectForEntityForName:@"Contact" inManagedObjectContext:context];
    [newContact setNickname:nickname];
    [newContact setState:stateNo];
    [newContact setLastActive:[NSDate date]];
    
    [appDelegate saveContext];
    
    return newContact;
}

+(void)setState:(State)state onContact:(Contact *)contact
{
    [contact setState:state];
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    [appDelegate saveContext];
}

+(void)setLastActive:(NSDate *)date onContact:(Contact *)contact
{
    [contact setLastActive:date];
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    [appDelegate saveContext];
}

+(void)deleteContact:(Contact *)contact
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];

    [context deleteObject:contact];
    
    [appDelegate saveContext];
}

+(void)deleteAllContacts
{
    // Fetch all contacts
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Contact" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    [fetchRequest setIncludesPropertyValues:NO]; //only fetch the managedObjectID

    NSError *error = nil;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects == nil) {
        // Handle the error
        NSLog(@"deleteAllContacts - fetch - ERROR: %@", error);
    }
    
    // Delete all contacts
    for (Contact *contact in fetchedObjects)
    {
        [context deleteObject:contact];
    }
    
    // Save
    [appDelegate saveContext];
}


@end