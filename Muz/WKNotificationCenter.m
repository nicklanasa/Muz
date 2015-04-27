//
//  WKNotificationCenter.m
//  WatchKitDemo
//
//  Created by Nick Lanasa on 3/26/15.
//  Copyright (c) 2015 EvolveNow. All rights reserved.
//

#import "WKNotificationCenter.h"

#if !__has_feature(objc_arc)
#error This class requires automatic reference counting
#endif

#include <CoreFoundation/CoreFoundation.h>

static NSString * const WKNotificationName = @"WKNotificationName";

@interface WKNotificationCenter()

@property (nonatomic, copy) NSString *applicationGroupIdentifier;
@property (nonatomic, strong) NSMutableDictionary *observerBlocks;
@property (nonatomic, strong) NSMutableDictionary *selectors;
@property (nonatomic, strong) NSMutableDictionary *observers;

@end


@implementation WKNotificationCenter

- (id)init:(NSString *)identifier {
    if ((self = [super init])) {
        if (![[NSFileManager defaultManager] respondsToSelector:@selector(containerURLForSecurityApplicationGroupIdentifier:)]) {
            //Protect the user of a crash because of iOSVersion < iOS7
            return nil;
        }
        
        _applicationGroupIdentifier = [identifier copy];
        _observerBlocks = [NSMutableDictionary dictionary];
        _selectors = [NSMutableDictionary dictionary];
        _observers = [NSMutableDictionary dictionary];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didReceiveNotification:)
                                                     name:WKNotificationName
                                                   object:nil];
    }
    
    return self;
}

+ (instancetype)defaultCenterWithGroupIndentifier:(NSString *)identifier
{
    static WKNotificationCenter *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[WKNotificationCenter alloc] init:identifier];
    });
    
    return sharedInstance;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    CFNotificationCenterRef const center = CFNotificationCenterGetDarwinNotifyCenter();
    CFNotificationCenterRemoveEveryObserver(center, (__bridge const void *)(self));
}

#pragma mark - Private

- (NSString *)notificationDirectoryPath {
    NSURL *appGroupContainer = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:self.applicationGroupIdentifier];
    NSString *appGroupContainerPath = [appGroupContainer path];
    NSString *directoryPath = appGroupContainerPath;
    
    [[NSFileManager defaultManager]  createDirectoryAtPath:directoryPath
                withIntermediateDirectories:YES
                                 attributes:nil
                                      error:NULL];
    
    return directoryPath;
}

- (NSString *)filePathForIdentifier:(NSString *)identifier {
    if (identifier == nil || identifier.length == 0) {
        return nil;
    }
    
    NSString *directoryPath = [self notificationDirectoryPath];
    NSString *fileName = [NSString stringWithFormat:@"%@.archive", identifier];
    NSString *filePath = [directoryPath stringByAppendingPathComponent:fileName];
    
    return filePath;
}

- (void)writeNotificationObject:(id)notificationObject toFileWithIdentifier:(NSString *)identifier {
    if (identifier == nil) {
        return;
    }
    
    if (notificationObject) {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:notificationObject];
        NSString *filePath = [self filePathForIdentifier:identifier];
        
        if (data == nil || filePath == nil) {
            return;
        }
        
        if (![data writeToFile:filePath atomically:YES]) {
            return;
        }
    }
    
    [self sendNotificationWithIdentifier:identifier];
}

- (id)notificationObjectFromFileWithIdentifier:(NSString *)identifier {
    if (identifier == nil) {
        return nil;
    }
    
    NSData *data = [NSData dataWithContentsOfFile:[self filePathForIdentifier:identifier]];
    
    if (data == nil) {
        return nil;
    }
    
    id notificationObject = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    return notificationObject;
}

- (void)removeFileForIdentifier:(NSString *)identifier {
    [[NSFileManager defaultManager] removeItemAtPath:[self filePathForIdentifier:identifier]
                                               error:NULL];
}

- (void)sendNotificationWithIdentifier:(NSString *)identifier {
    CFNotificationCenterRef const center = CFNotificationCenterGetDarwinNotifyCenter();
    CFDictionaryRef const userInfo = NULL;
    BOOL const deliverImmediately = YES;
    CFStringRef str = (__bridge CFStringRef)identifier;
    CFNotificationCenterPostNotification(center, str, NULL, userInfo, deliverImmediately);
}

- (void)addObserverForNotificationsWithIdentifier:(NSString *)identifier
                                         observer:(id)observer {
    CFNotificationCenterRef const center = CFNotificationCenterGetDarwinNotifyCenter();
    CFStringRef str = (__bridge CFStringRef)identifier;
    CFNotificationCenterAddObserver(center,
                                    (__bridge const void *)(observer),
                                    notificationCallback,
                                    str,
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately);
}

- (void)removeObserverForNotificationsWithIdentifier:(NSString *)identifier observer:(id)observer {
    
    [self.observerBlocks setValue:nil forKey:identifier];
    [self.selectors setValue:nil forKey:identifier];
    
    CFNotificationCenterRef const center = CFNotificationCenterGetDarwinNotifyCenter();
    CFStringRef str = (__bridge CFStringRef)identifier;
    CFNotificationCenterRemoveObserver(center,
                                       (__bridge const void *)(observer),
                                       str,
                                       NULL);
}

- (void)didReceiveNotification:(NSNotification *)notification {
    typedef void (^NotificationBlock)(id notificationObject);
    
    NSDictionary *userInfo = notification.userInfo;
    NSString *identifier = [userInfo valueForKey:@"identifier"];
    
    if (identifier != nil) {
        NotificationBlock observerBlock = [self observerBlockForIdentifier:identifier];
        NSValue *selectorValue = [self observerSelectorForIdentifier:identifier];
        
        id notificationObject = [self notificationObjectFromFileWithIdentifier:identifier];
        
        if (observerBlock) {
            observerBlock(notificationObject);
        }
        
        if (selectorValue) {
            SEL aSel = selectorValue.pointerValue;
            
            id observer = [self observerForIdentifier:identifier];
            
            [observer performSelector:aSel withObject:notificationObject afterDelay:0];
        }
    }
}

- (id)observerBlockForIdentifier:(NSString *)identifier {
    return [self.observerBlocks valueForKey:identifier];
}

- (id)observerSelectorForIdentifier:(NSString *)identifier {
    return [self.selectors valueForKey:identifier];
}

- (id)observerForIdentifier:(NSString *)identifier {
    return [self.observers valueForKey:identifier];
}

void notificationCallback(CFNotificationCenterRef center,
                          void * observer,
                          CFStringRef name,
                          void const * object,
                          CFDictionaryRef userInfo) {
    NSString *identifier = (__bridge NSString *)name;
    [[NSNotificationCenter defaultCenter] postNotificationName:WKNotificationName
                                                        object:nil
                                                      userInfo:@{@"identifier" : identifier}];
}

#pragma mark - Public

- (void)postNotificationObject:(id <NSCoding>)notificationObject
              identifier:(NSString *)identifier; {
    [self writeNotificationObject:notificationObject toFileWithIdentifier:identifier];
}

- (void)addObserverWithIdentifier:(NSString *)identifier
                         observer:(id)observer
                         selector:(SEL)aSelector
                           object:(id)anObject
{
    if (identifier != nil) {
        [self.selectors setValue:[NSValue valueWithPointer:aSelector] forKey:identifier];
        [self.observers setValue:observer forKey:identifier];
        [self addObserverForNotificationsWithIdentifier:identifier
                                               observer:observer];
    }
}

- (void)addObserverWithIdentifier:(NSString *)identifier
                              observer:(void (^)(id notificationObject))observer
{
    if (identifier != nil) {
        [self.observerBlocks setValue:observer forKey:identifier];
        [self addObserverForNotificationsWithIdentifier:identifier
                                               observer:self];
    }
}

- (void)removeObserverWithIdentifier:(NSString *)identifier {
    if (identifier != nil) {
        [self removeObserverForNotificationsWithIdentifier:identifier
                                                  observer:self];
    }
}

- (void)removeObserverWithIdentifier:(NSString *)identifier
                            observer:(id)observer
{
    if (identifier != nil) {
        [self removeObserverForNotificationsWithIdentifier:identifier
                                                  observer:observer ];
    }
}

@end
