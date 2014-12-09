//
//  AppDelegate.m
//  PingYou
//
//  Created by André Hansson on 15/10/14.
//  Copyright (c) 2014 PingPal AB. All rights reserved.
//

#import "AppDelegate.h"
#import "CoreDataWrapper.h"
#import "DataStore.h"
#import "LoginTableViewController.h"

#import <PPLocationManager/Outbox.h>
#import <PPLocationManager/PPLocationManager.h>

#warning ADD KEYS
#define PUBLIC_KEY @"PUBLIC"
#define PRIVATE_KEY @"PRIVATE"

@implementation AppDelegate{
    AccessHandler accessHandler;
    
    Inbox systemInbox;
}

void (^_completionHandler)(UIBackgroundFetchResult);

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    // Outbox
    [Outbox setAPIKeys:PUBLIC_KEY andPrivate:PRIVATE_KEY];
    
    //[Outbox setLogLevelMask:LOG_FLAG_DEBUG andContextMask:LOG_CONTEXT_ALL];
    
    NSString *startTicket = [[NSUserDefaults standardUserDefaults] objectForKey:@"pingpal.ticket"];
    
    [Outbox startHistory:startTicket andSaveBlock:^(NSError *error, NSString *ticket) {
        if (error) {
            NSLog(@"startHistoryandSaveBlock - Error: %@", error);
        }
        
        NSLog(@"startHistoryandSaveBlock - Ticket: %@", ticket);
        
        [[NSUserDefaults standardUserDefaults] setObject:ticket forKey:@"pingpal.ticket"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }];
    
    // PPLocationManager
    [PPLocationManager setup];
    
    accessHandler = ^(NSMutableDictionary *payload, NSMutableDictionary *options, AccessYes yes) {
        NSLog(@"accessHandler Payload: %@. Options: %@", payload, options);
        
        Contact *contact = [CoreDataWrapper fetchContactWithNickname:[options[@"from"] substringFromIndex:1]];
        
        // If the contact isn't added yet, do that using the nickname found in the options with the key from. We also need to remove the first character, the #, because we don't want that in our nickname. 
        if (!contact)
        {
            contact = [CoreDataWrapper createNewContact:[options[@"from"] substringFromIndex:1]];
        }
        
        // Check the state on the contact to see if it's been permitted to ping. If it's not permitted, send a message to let it know.
        if (contact.state == stateYes)
        {
            yes();
        }
        else
        {
            // When we send a message with the yourseq it will arrive in the inbox the sender specified. in this case it's the pingInbox found in MapViewController.m
            [Outbox put:options[@"from"] withPayload:@{@"accessDenied":@"accessDenied"} andOptions:@{@"yourseq":options[@"yourseq"]}];
        }
    };
    [PPLocationManager setAccesshandler:accessHandler];
    
    // Create a weak reference to self that we will use in the systemInbox block to avoid a retain cycle
    __weak typeof(self) weakSelf = self;
    
    // The systemInbox is used to receive messages if you get banned or reported someone
    systemInbox = ^(NSMutableDictionary *payload, NSMutableDictionary *options, Outbox *outbox) {
        NSLog(@"systemInbox - Payload: %@. Options: %@", payload, options);
        
        // Make a strong reference to the weak reference. This will make sure the weak reference isn't released before the end of the block.
        __strong typeof(self) strongSelf = weakSelf;
        
        if (strongSelf)
        {
            if ([payload[@"action"] isEqualToString:@"ban"])
            {
                // Remove the tags
                [DataStore setAliasTag:NULL];
                [DataStore setDeviceTag:NULL];
                
                // Go back to login screen
                LoginTableViewController *login = (LoginTableViewController*)[strongSelf.window rootViewController];
                [login closeContacts];
                
                // Remove all contacts
                [CoreDataWrapper deleteAllContacts];
                
                // Present a message about ban reason
                [[[UIAlertView alloc]initWithTitle:@"YOU HAVE BEEN BANNED" message:@"Your username was violating the EULA and you have been banned" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]show];
            }
            else if ([payload[@"action"] isEqualToString:@"reportAnswered"])
            {
                // Remove the banned contact from phone
                NSString *bannedNickname = [payload[@"banned"] substringFromIndex:1];
                
                Contact *contactToDelete = [CoreDataWrapper fetchContactWithNickname:bannedNickname];
                if (contactToDelete) {
                    [CoreDataWrapper deleteContact:contactToDelete];
                }
            }
        }
    };
    [Outbox attachInbox:systemInbox withPredicate:[NSPredicate predicateWithFormat:@"options.from == '#mod'"]];

    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}


#pragma mark - Push

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSLog(@"didRegisterForRemoteNotificationsWithDeviceToken");
    
    NSString *deviceTag = [DataStore deviceTag];
    
    if (deviceTag)
    {
        // Register for push on the Apptimate servers. Remember to change debug before you release.
        [Outbox registerForPushNotifications:deviceTag withPushToken:deviceToken isDebug:NO andCallback:^(NSError *error) {
            if (!error) {
                NSLog(@"Push registered");
                // Save that we registered push so we don't try to do it again.
                [DataStore setIsPushRegistered:YES];
            }else{
                NSLog(@"registerForPushNotifications ERROR: %@", error);
            }
        }];
    }
}

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error{
    NSLog(@"didFailToRegisterForRemoteNotificationsWithError: %@", error);
}

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler{
    NSLog(@"didReceiveRemoteNotification:fetchCompletionHandler: %@", userInfo);
    
    if (application.applicationState == UIApplicationStateBackground)
    {
        NSLog(@"Received push in background");
        // The app is in the background. Fetch messages.
        
        // Outbox will automatically fetch on bind
        [Outbox resume];
        
        // Save a reference to tha completionHandler
        _completionHandler = [completionHandler copy];
        
        // Give the outbox some time to set up the connection to the server and fetch any new messages. Then we need to call the completionHandler.
        [self performSelector:@selector(done) withObject:NULL afterDelay:7];
    }
}

-(void)done
{
    // If the user has not opend the app at this point we need to resign the outbox again.
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground)
    {
        [Outbox resign];
    }
    
    // Call the completionHandler so ios can shut down backgroundmode.
    _completionHandler(UIBackgroundFetchResultNewData);
}



#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "se.pingpal.PingYou" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"PingYou" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"PingYou.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

@end