//
//  LastFmBuyLink.m
//  Muz
//
//  Created by Nick Lanasa on 12/16/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

#import "LastFmBuyLink.h"

static NSString * const LastFmBuyLinkKeycurrency = @"currency";
static NSString * const LastFmBuyLinkKeyicon = @"icon";
static NSString * const LastFmBuyLinkKeyname = @"name";
static NSString * const LastFmBuyLinkKeyprice = @"price";
static NSString * const LastFmBuyLinkKeyurl = @"url";


@interface LastFmBuyLink  ()

@property (nonatomic, readwrite, strong) NSString *currency;
@property (nonatomic, readwrite, strong) NSURL *icon;
@property (nonatomic, readwrite, strong) NSString *name;
@property (nonatomic, readwrite, strong) NSNumber *price;
@property (nonatomic, readwrite, strong) NSURL *url;

@end


@implementation LastFmBuyLink

- (id) initWithJSON:(NSDictionary *)json
{
    self = [super init];
    if( self)
        [self parseJSON:json];
    return self;
}

- (void) parseJSON:(NSDictionary *)json
{
    //  LastFmBuyLinkKeycurrency
    if( [json[ LastFmBuyLinkKeycurrency] isKindOfClass:[NSString class]])
        self.currency = json[ LastFmBuyLinkKeycurrency];
    
    //  LastFmBuyLinkKeyicon
    if( [json[ LastFmBuyLinkKeyicon] isKindOfClass:[NSURL class]])
        self.icon = json[ LastFmBuyLinkKeyicon];
    
    //  LastFmBuyLinkKeyname
    if( [json[ LastFmBuyLinkKeyname] isKindOfClass:[NSString class]])
        self.name = json[ LastFmBuyLinkKeyname];
    
    //  LastFmBuyLinkKeyprice
    if( [json[ LastFmBuyLinkKeyprice] isKindOfClass:[NSNumber class]])
        self.price = json[ LastFmBuyLinkKeyprice];
    
    //  LastFmBuyLinkKeyurl
    if( [json[ LastFmBuyLinkKeyurl] isKindOfClass:[NSURL class]])
        self.url = json[ LastFmBuyLinkKeyurl];
    
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"<LastFmBuyLink: currency = %@, icon = %@, name = %@, price = %@, url = %@>", self.currency, self.icon, self.name, self.price, self.url];
}

@end
