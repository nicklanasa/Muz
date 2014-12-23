//
//  LastFmEvent.m
//  Muz
//
//  Created by Nick Lanasa on 12/16/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

#import "LastFmEvent.h"
#import <NSString-HTML/NSString+HTML.h>
#import "NSString+Lyrics.h"

static NSString * const LastFmEventKeycity = @"city";
static NSString * const LastFmEventKeyheadliner = @"headliner";
static NSString * const LastFmEventKeycountry = @"country";
static NSString * const LastFmEventKeyattendance = @"attendance";
static NSString * const LastFmEventKeytitle = @"title";
static NSString * const LastFmEventKeystartDate = @"startDate";
static NSString * const LastFmEventKeyimage = @"image";
static NSString * const LastFmEventKeyvenue = @"venue";
static NSString * const LastFmEventKeydescription = @"description";
static NSString * const LastFmEventKeyurl = @"url";


@interface LastFmEvent  ()

@property (nonatomic, readwrite, strong) NSString *city;
@property (nonatomic, readwrite, strong) NSNumber *attendance;
@property (nonatomic, readwrite, strong) NSString *country;
@property (nonatomic, readwrite, strong) NSString *headliner;
@property (nonatomic, readwrite, strong) NSDate *startDate;
@property (nonatomic, readwrite, strong) NSURL *image;
@property (nonatomic, readwrite, strong) NSString *title;
@property (nonatomic, readwrite, strong) NSString *venue;
@property (nonatomic, readwrite, strong) NSString *eventDescription;
@property (nonatomic, readwrite, strong) NSURL *url;

@end


@implementation LastFmEvent

- (id) initWithJSON:(NSDictionary *)json
{
    self = [super init];
    if( self)
        [self parseJSON:json];
    return self;
}

- (void) parseJSON:(NSDictionary *)json
{
    //  LastFmEventKeycity
    if( [json[ LastFmEventKeycity] isKindOfClass:[NSString class]])
        self.city = json[ LastFmEventKeycity];
    
    //  LastFmEventKeyattendance
    if( [json[ LastFmEventKeyattendance] isKindOfClass:[NSNumber class]])
        self.attendance = json[ LastFmEventKeyattendance];
    
    //  LastFmEventKeycountry
    if( [json[ LastFmEventKeycountry] isKindOfClass:[NSString class]])
        self.country = json[ LastFmEventKeycountry];
    
    //  LastFmEventKeyheadliner
    if( [json[ LastFmEventKeyheadliner] isKindOfClass:[NSString class]])
        self.headliner = json[ LastFmEventKeyheadliner];
    
    //  LastFmEventKeystartDate
    if( [json[ LastFmEventKeystartDate] isKindOfClass:[NSDate class]])
        self.startDate = json[ LastFmEventKeystartDate];
    
    //  LastFmEventKeyimage
    if( [json[ LastFmEventKeyimage] isKindOfClass:[NSURL class]])
        self.image = json[ LastFmEventKeyimage];
    
    //  LastFmEventKeytitle
    if( [json[ LastFmEventKeytitle] isKindOfClass:[NSString class]])
        self.title = json[ LastFmEventKeytitle];
    
    //  LastFmEventKeyvenue
    if( [json[ LastFmEventKeyvenue] isKindOfClass:[NSString class]])
        self.venue = json[ LastFmEventKeyvenue];
    
    //  LastFmEventKeydescription
    if( [json[ LastFmEventKeydescription] isKindOfClass:[NSString class]])
        self.eventDescription = [[json[ LastFmEventKeydescription] kv_decodeHTMLCharacterEntities] stringByStrippingHTML];
    
    //  LastFmEventKeyurl
    if( [json[ LastFmEventKeyurl] isKindOfClass:[NSURL class]])
        self.url = json[ LastFmEventKeyurl];
    
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"<LastFmEvent: city = %@, attendance = %@, country = %@, headliner = %@, startDate = %@, image = %@, title = %@, venue = %@, eventDescription = %@, url = %@>", self.city, self.attendance, self.country, self.headliner, self.startDate, self.image, self.title, self.venue, self.eventDescription, self.url];
}

@end
