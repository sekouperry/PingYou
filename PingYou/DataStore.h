//
//  DataStorer.h
//  PingYou
//
//  Created by André Hansson on 15/10/14.
//  Copyright (c) 2014 PingPal AB. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DataStore : NSObject

// Used to save and get thing from NSUserDefaults

+(NSString*)deviceTag;

+(void)setDeviceTag:(NSString*)tag;

+(NSString*)aliasTag;

+(void)setAliasTag:(NSString*)tag;


+(BOOL)isPushRegistered;

+(void)setIsPushRegistered:(BOOL)push;


+(BOOL)hasShownFirstContactTips;

+(void)setHasShownFirstContactTips:(BOOL)hasShownFirstContactTips;

+(BOOL)hasShownFirstTimeMapViewTip;

+(void)setHasShownFirstTimeMapViewTip:(BOOL)hasShownFirstTimeMapViewTip;

@end