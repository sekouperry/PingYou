//
//  DataStorer.m
//  PingYou
//
//  Created by André Hansson on 15/10/14.
//  Copyright (c) 2014 PingPal AB. All rights reserved.
//

#import "DataStore.h"

@implementation DataStore

+(NSString *)deviceTag{
    return [[NSUserDefaults standardUserDefaults]stringForKey:@"deviceTag"];
}

+(void)setDeviceTag:(NSString *)tag{
    [[NSUserDefaults standardUserDefaults]setObject:tag forKey:@"deviceTag"];
    [[NSUserDefaults standardUserDefaults]synchronize];
}

+(NSString *)aliasTag{
    return [[NSUserDefaults standardUserDefaults]stringForKey:@"aliasTag"];
}

+(void)setAliasTag:(NSString *)tag{
    [[NSUserDefaults standardUserDefaults]setObject:tag forKey:@"aliasTag"];
    [[NSUserDefaults standardUserDefaults]synchronize];
}


+(BOOL)isPushRegistered{
    return [[NSUserDefaults standardUserDefaults]boolForKey:@"pushRegistered"];
}

+(void)setIsPushRegistered:(BOOL)push{
    [[NSUserDefaults standardUserDefaults]setBool:push forKey:@"pushRegistered"];
    [[NSUserDefaults standardUserDefaults]synchronize];
}


+(BOOL)hasShownFirstContactTips
{
    return [[NSUserDefaults standardUserDefaults]boolForKey:@"hasShownFirstContactTips"];
}

+(void)setHasShownFirstContactTips:(BOOL)hasShownFirstContactTips
{
    [[NSUserDefaults standardUserDefaults]setBool:hasShownFirstContactTips forKey:@"hasShownFirstContactTips"];
    [[NSUserDefaults standardUserDefaults]synchronize];
}

+(BOOL)hasShownFirstTimeMapViewTip
{
    return [[NSUserDefaults standardUserDefaults]boolForKey:@"hasShownFirstTimeMapViewTip"];

}

+(void)setHasShownFirstTimeMapViewTip:(BOOL)hasShownFirstTimeMapViewTip
{
    [[NSUserDefaults standardUserDefaults]setBool:hasShownFirstTimeMapViewTip forKey:@"hasShownFirstTimeMapViewTip"];
    [[NSUserDefaults standardUserDefaults]synchronize];
}


@end