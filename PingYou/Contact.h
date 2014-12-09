//
//  Contact.h
//  PingYou
//
//  Created by André Hansson on 18/10/14.
//  Copyright (c) 2014 PingPal AB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

typedef enum States : int16_t{
    stateDeleted = 1,
    stateNo = 2,
    stateYes = 3
}State;

@interface Contact : NSManagedObject

@property (nonatomic, retain) NSDate * lastActive;
@property (nonatomic, retain) NSString * nickname;
@property (nonatomic) State state;

@end
