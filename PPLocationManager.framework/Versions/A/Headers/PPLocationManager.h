//
//  PPLocationManager.h
//  PPLocationManager
//
//  Created by André Hansson on 04/12/13.
//  Copyright (c) 2013 PingPal AB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "Outbox.h"

typedef void (^AccessYes) ();
typedef void (^AccessHandler) (NSMutableDictionary*, NSMutableDictionary*, AccessYes);

typedef enum Authorizations : int16_t{
    AuthorizationAlways = 1,
    AuthorizationWhenInUse = 2
}Authorization;

@interface PPLocationManager : NSObject

/** This is used to set a block to handle access. You can use the information in the block to check if you want to answer the ping or not. If you want to answer the ping simply run the AccessYes block. If the block is not set every ping will automatically be accepted.
 *  @param accessHandlerBlock The block to handle the access */
+(void)setAccesshandler:(AccessHandler)accessHandlerBlock;

/** Initialises the PPLocationManager and setups the inboxes to receive pings. Needs to be run only once and after the start of Outbox. */
+(void)setup;

/** Set the authorization of PPLocationManager. Required only for iOS 8 and above. You need to add the appropriate keys in your info.plist file. NSLocationAlwaysUsageDescription or NSLocationWhenInUseUsageDescription depending on which one you will be using. The user prompt to approve location services will contain the text from the one you used.
 *   @param authorization The authorization you want to use. Possible values are AuthorizationAlways or AuthorizationWhenInUse. Defaults to AuthorizationAlways. */
+(void)setAuthorization:(Authorization)authorization;

/** If you want the tracking locations to be sent with push you need to set the push dictionary here.
 *   @param push The push dictionary */
+(void)answerTrackingWithPush:(NSDictionary*)push;

/** If you want the device locations to be sent with push you need to set the push dictionary here.
 *   @param push The push dictionary */
+(void)answerDevicePositionWithPush:(NSDictionary*)push;

/** Used to track another device.
 *  @param tag The tag of the user you want to track.
 *  @param inbox The inbox where you want to receive the locations.
 *  @param options The options data. The same as on Outbox put:withPayload:andOptions: */
+(void)trackDevicePosition:(NSString*)tag WithInbox:(Inbox)inbox AndOptions:(NSDictionary*)options;

/** Used to track another device.
 *  @param tag The tag of the user you want to track.
 *  @param sec For how long you want to track in seconds. If set to 0 it will continue to track until it’s stopped.
 *  @param inbox The inbox where you want to receive the locations.
 *  @param options The options data. The same as on Outbox put:withPayload:andOptions: */
+(void)trackDevicePosition:(NSString*)tag withDuration:(double)sec AndInbox:(Inbox)inbox AndOptions:(NSDictionary*)options;

/** Sends a message to the tag that stops tracking. Should only be called if you are tracking that tag.
 *  @param tag The tag of the user you want to stop tracking */
+(void)stopTrackingDevicePosition:(NSString*)tag;

/** Used to get a position from another user. When using this method the GPS accuracy will be 100 meters and the timeout time will be 30 seconds. If you want to set accuracy or timeout time yourself you need to use one of the other getDevicePosition methods.
 *  @param tag The tag of the user you want to track.
 *  @param inbox The inbox where you want to receive the location.
 *  @param options The options data. The same as on Outbox put:withPayload:andOptions: */
+(void)getDevicePosition:(NSString*)tag WithInbox:(Inbox)inbox AndOptions:(NSDictionary*)options;

/** Used to get a position from another user. It will return a position when it comes within the wanted accuracy, or when the time runs out.
 *  @param tag The tag of the user you want to track.
 *  @param meters The accuracy you want the position to be, in meters. Defaults to 100. If set to 0 the default will be used.
 *  @param inbox The inbox where you want to receive the location.
 *  @param options The options data. The same as on Outbox put:withPayload:andOptions: */
+(void)getDevicePosition:(NSString *)tag withAccuracy:(double)meters AndInbox:(Inbox)inbox AndOptions:(NSDictionary*)options;

/** Used to get a position from another user. It will return a position when it comes within the wanted accuracy, or when the time runs out.
 *  @param tag The tag of the user you want to track.
 *  @param seconds The amount of time you want to wait for a position within your accuracy, in seconds. Defaults to 30. If set to 0 the default will be used.
 *  @param inbox The inbox where you want to receive the location.
 *  @param options The options data. The same as on Outbox put:withPayload:andOptions: */
+(void)getDevicePosition:(NSString *)tag withTimeout:(double)seconds AndInbox:(Inbox)inbox AndOptions:(NSDictionary*)options;

/** Used to get a position from another user. It will return a position when it comes within the wanted accuracy, or when the time runs out.
 *  @param tag The tag of the user you want to track.
 *  @param meters The accuracy you want the position to be, in meters. Defaults to 100. If set to 0 the default will be used.
 *  @param seconds The amount of time you want to wait for a position within your accuracy, in seconds. Defaults to 30. If set to 0 the default will be used.
 *  @param inbox The inbox where you want to receive the location.
 *  @param options The options data. The same as on Outbox put:withPayload:andOptions: */
+(void)getDevicePosition:(NSString *)tag withAccuracy:(double)meters andTimeout:(double)seconds AndInbox:(Inbox)inbox AndOptions:(NSDictionary*)options;


@end