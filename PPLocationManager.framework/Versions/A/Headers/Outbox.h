
#import <Foundation/Foundation.h>

#ifndef LOG_CONTEXT_ALL
#define LOG_CONTEXT_ALL             INT_MAX
#endif

#ifndef LOG_CONTEXT_UNSPECIFIED
#define LOG_CONTEXT_UNSPECIFIED     (1 << 0)
#endif

#ifndef LOG_CONTEXT_SERVER
#define LOG_CONTEXT_SERVER          (1 << 1)
#endif

#ifndef LOG_CONTEXT_CONNECTION
#define LOG_CONTEXT_CONNECTION      (1 << 2)
#endif

#ifndef LOG_CONTEXT_LOCAL
#define LOG_CONTEXT_LOCAL           (1 << 3)
#endif

#ifndef LOG_CONTEXT_COMMUNICATION
#define LOG_CONTEXT_COMMUNICATION   (1 << 4)
#endif

#ifndef LOG_FLAG_ERROR
#define LOG_FLAG_ERROR    (1 << 0)  // 0...00001
#endif

#ifndef LOG_FLAG_WARN
#define LOG_FLAG_WARN     (1 << 1)  // 0...00010
#endif

#ifndef LOG_FLAG_INFO
#define LOG_FLAG_INFO     (1 << 2)  // 0...00100
#endif

#ifndef LOG_FLAG_DEBUG
#define LOG_FLAG_DEBUG    (1 << 3)  // 0...01000
#endif

#ifndef LOG_FLAG_VERBOSE
#define LOG_FLAG_VERBOSE  (1 << 4)  // 0...10000
#endif


@class Outbox;

typedef void (^Inbox) (NSMutableDictionary *payload, NSMutableDictionary *options, Outbox *outbox);

@interface Outbox : NSObject {
    
    NSString *to;
    NSString *from;
    NSString *your;
    NSString *origin;
}

- (Outbox *) init: (NSMutableDictionary *) payload : (NSMutableDictionary *) options;

- (void) put: (NSDictionary *) payload withOptions: (NSDictionary*) options andInbox: (Inbox) inbox;

+ (void) setAPIKeys: (NSString *) publicKey andPrivate: (NSString *) privateKey;

+ (void) setAPIKeys: (NSString *) publicKey andPrivate: (NSString *) privateKey andOptions: (NSDictionary *) options;

+ (void) put: (NSString *) to withPayload: (NSDictionary *) payload;

+ (void) put: (NSString *) to withPayload: (NSDictionary *) payload andOptions: (NSDictionary *) options;

+ (void) put: (NSString *) to withPayload: (NSDictionary *) payload andOptions: (NSDictionary *) options andInbox: (Inbox) inbox;

+ (void) attachInbox: (Inbox) inbox;

+ (void) attachInbox: (Inbox) inbox withPredicate: (NSPredicate *) predicate;

+ (void) detachInbox: (Inbox) inbox;

+ (void) detachInbox: (Inbox) inbox withPredicate: (NSPredicate *) predicate;

+ (void) resume;

+ (void) resign;

+ (NSString *) hashIfTag: (NSString *) tag;

+ (void) startWithTag: (NSString *) tag;

+ (void) startWithTag: (NSString *) tag andCallback: (void(^)(NSError *error)) callback;

+ (void) startWithTag: (NSString *) child andAlias: (NSString *) parent;

+ (void) startWithTag: (NSString *) child andAlias: (NSString *) parent andCallback: (void(^)(NSError * error)) callback;

+ (void) startLifecycle;

+ (void) stopLifecycle;

+ (void) startHistory: (NSString *) ticket andSaveBlock: (void(^)(NSError *error, NSString *ticket)) save;

+ (void) stopHistory;

+ (NSString *) createUniqueTag;

+ (void) registerTag: (NSString *) tag;

+ (void) registerTag: (NSString *) tag withCallback: (void(^)(NSError *error)) callback;

+ (void) unregisterTag: (NSString *) tag;

+ (void) unregisterTag: (NSString *) tag withCallback: (void(^)(NSError *error)) callback;

+ (void) subscribeTag: (NSString *) child toParent: (NSString *) parent;

+ (void) subscribeTag: (NSString *) child toParent: (NSString *) parent withCallback: (void(^)(NSError *error)) callback;

+ (void) unsubscribeTag: (NSString *) child fromParent: (NSString *) parent;

+ (void) unsubscribeTag: (NSString *) child fromParent: (NSString *) parent withCallback: (void(^)(NSError *error)) callback;

+ (void) resolveTag: (NSString *) tag withCallback: (void(^)(NSError *error, NSArray *list)) callback;

+ (void) tagExists: (NSString *) tag withCallback: (void(^)(NSError *error, BOOL exists)) callback;

+ (void) tagsExist: (NSArray *) tags withCallback: (void(^)(NSError *error, NSArray *list)) callback;

+ (void) registerForPushNotifications: (NSString *) tag withPushToken: (NSData *) token isDebug: (BOOL) debug;

+ (void) registerForPushNotifications: (NSString *) tag withPushToken: (NSData *) token isDebug: (BOOL) debug andCallback: (void(^)(NSError *error)) callback;

+ (void) stopLogging;

+ (void) setLogLevelMask: (int) logLevel  andContextMask:(int) whiteListMask;


@end

