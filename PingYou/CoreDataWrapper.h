//
//  CoreDataWrapper.h
//  PingYou
//
//  Created by André Hansson on 18/10/14.
//  Copyright (c) 2014 PingPal AB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Contact.h"

@interface CoreDataWrapper : NSObject

// Used to fetch, create and change CoreData objects

+(NSArray*)fetchContacts;

+(NSArray*)fetchDeletedContacts;

+(Contact*)fetchContactWithNickname:(NSString*)nickname;

+(Contact*)createNewContact:(NSString*)nickname;

+(void)setState:(State)state onContact:(Contact*)contact;

+(void)setLastActive:(NSDate*)date onContact:(Contact*)contact;

+(void)deleteContact:(Contact*)contact;

+(void)deleteAllContacts;

@end