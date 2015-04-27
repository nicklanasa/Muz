//
//  WKNotificationCenter.h
//  WatchKitDemo
//
//  Created by Nick Lanasa on 3/26/15.
//  Copyright (c) 2015 EvolveNow. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WKNotificationCenter : NSObject


/**
 Designated Initializer. This method must be called with an application group identifier that will
 be used to contain passed messages.
 
 @param identifier An application group identifier
 */
+ (instancetype)defaultCenterWithGroupIndentifier:(NSString *)identifier;


- (void)postNotificationObject:(id <NSCoding>)notificationObject
               identifier:(NSString *)identifier;

/**
 This method begins listening for notifications of changes to a notification object with a specific identifier.
 If notifications are observed then the given listener block will be called along with the actual
 notification object.

 @param identifier The identifier for the notification.
 @param listener A listener block called with the notificationObject parameter when a notification
 is observed.
 */
- (void)addObserverWithIdentifier:(NSString *)identifier
                              observer:(void (^)(id notificationObject))observer;

- (void)addObserverWithIdentifier:(NSString *)identifier
                         observer:(id)observer
                         selector:(SEL)aSelector
                           object:(id)anObject;

/**
 This method stops listening for change notifications for a given notification identifier.
 
 @param identifier The identifier for the message
 */
- (void)removeObserverWithIdentifier:(NSString *)identifier;

- (void)removeObserverWithIdentifier:(NSString *)identifier observer:(id)observer;


@end
