//
//  LastFmArtist.m
//  Muz
//
//  Created by Nick Lanasa on 12/14/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "LastFmArtist.h"
#import "NSString+Lyrics.h"
#import <NSString-HTML/NSString+HTML.h>

static NSString * const artistKeyName = @"name";
static NSString * const artistKeyUrl = @"url";
static NSString * const artistKeyImage = @"image";
static NSString * const artistKeyBio = @"bio";
static NSString * const artistKeyListeners = @"listeners";
static NSString * const artistKeyOntour = @"ontour";
static NSString * const artistKeyPlaycount = @"playcount";
static NSString * const artistKeySummary = @"summary";


@interface LastFmArtist  ()

@property (nonatomic, readwrite, strong) NSString *name;
@property (nonatomic, readwrite, strong) NSURL *artistURL;
@property (nonatomic, readwrite, strong) NSURL *imageURL;
@property (nonatomic, readwrite, strong) NSString *bio;
@property (nonatomic, readwrite, strong) NSString *summary;
@property (nonatomic, readwrite, strong) NSNumber *listeners;
@property (nonatomic, readwrite, strong) NSNumber *plays;
@property (nonatomic, readwrite, strong) NSNumber *onTour;

@end

@implementation LastFmArtist

- (id) initWithJSON:(NSDictionary *)json
{
    self = [super init];
    if( self)
        [self parseJSON:json];
    return self;
}

- (void) parseJSON:(NSDictionary *)json
{
    if( [json[artistKeyName] isKindOfClass:[NSString class]])
        self.name = json[artistKeyName];
    
    if( [json[artistKeyUrl] isKindOfClass:[NSURL class]])
        self.artistURL = json[artistKeyUrl];
    
    if( [json[artistKeyImage] isKindOfClass:[NSURL class]])
        self.imageURL = json[artistKeyImage];
    
    if( [json[artistKeySummary] isKindOfClass:[NSString class]]) {
        self.summary = [json[artistKeySummary] stringByStrippingHTML];
    } else {
        self.summary = @"Summary unavailable";
    }
    
    if( [json[artistKeyBio] isKindOfClass:[NSString class]]) {
        self.bio = [[json[artistKeyBio] stringByStrippingHTML] kv_decodeHTMLCharacterEntities];
    } else {
        self.bio = @"";
    }
    
    if( [json[artistKeyListeners] isKindOfClass:[NSNumber class]]) {
        self.listeners = json[artistKeyListeners];
    } else {
        self.listeners = [NSNumber numberWithInt:0];
    }
    
    if( [json[artistKeyPlaycount] isKindOfClass:[NSNumber class]]) {
        self.plays = json[artistKeyPlaycount];
    } else {
        self.plays = [NSNumber numberWithInt:0];
    }
    
    if( [json[artistKeyOntour] isKindOfClass:[NSNumber class]]) {
        self.onTour = json[artistKeyOntour];
    } else {
        self.onTour = [NSNumber numberWithInt:0];
    }
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"<artist: name = %@, url = %@, image = %@>", self.name, self.artistURL, self.imageURL];
}

@end
