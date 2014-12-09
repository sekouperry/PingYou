
#import <Foundation/Foundation.h>

typedef void (^Callback) (NSDictionary *payload, NSDictionary *options);

typedef void (^Hook) (NSMutableDictionary *payload, NSMutableDictionary *options, Callback);

@interface Hooks : NSObject

+ (void) afterPut: (Hook) hook : (NSPredicate *) predicate;

+ (void) beforeSend: (Hook) hook : (NSPredicate *) predicate;

+ (void) afterReceive: (Hook) hook : (NSPredicate *) predicate;

+ (void) beforeNotify: (Hook) hook : (NSPredicate *) predicate;

+ (void) registerHook: (NSString *) key : (Hook) hook : (NSPredicate *) predicate;

+ (void) unregisterHook: (NSString *) key : (Hook) hook : (NSPredicate *) predicate;

+ (void) performHook: (NSString *) key : (id) payload : (id) options : (Callback) callback;

@end
