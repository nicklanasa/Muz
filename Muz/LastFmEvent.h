//
//  LastFmEvent.h
//  Muz
//
//  Created by Nick Lanasa on 12/16/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LastFmEvent : NSObject

@property (nonatomic, readonly, strong) NSString *city;
@property (nonatomic, readonly, strong) NSNumber *attendance;
@property (nonatomic, readonly, strong) NSString *country;
@property (nonatomic, readonly, strong) NSString *headliner;
@property (nonatomic, readonly, strong) NSDate *startDate;
@property (nonatomic, readonly, strong) NSURL *image;
@property (nonatomic, readonly, strong) NSString *title;
@property (nonatomic, readonly, strong) NSString *venue;
@property (nonatomic, readonly, strong) NSString *eventDescription;
@property (nonatomic, readonly, strong) NSURL *url;

- (id) initWithJSON:(NSDictionary *)json;
- (void) parseJSON:(NSDictionary *)json;
- (NSString *) description;


@end
