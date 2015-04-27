//
//  LastFmTrack.m
//  Muz
//
//  Created by Nick Lanasa on 2/9/15.
//  Copyright (c) 2015 Nytek Productions. All rights reserved.
//

#import "LastFmTrack.h"

static NSString * const RootKeyimage = @"image";
static NSString * const RootKeyname = @"name";
static NSString * const RootKeyplaycount = @"playcount";

static NSString * const RootKeyplayDate = @"date";
static NSString * const RootKeyplayArtist = @"artist";
static NSString * const RootKeyplayAlbum = @"album";

@interface LastFmTrack()

@property (nonatomic, readwrite, strong) NSString *image;
@property (nonatomic, readwrite, strong) NSString *name;
@property (nonatomic, readwrite, strong) NSNumber *playcount;
@property (nonatomic, readwrite, strong) NSDate *date;
@property (nonatomic, readwrite, strong) NSString *artist;
@property (nonatomic, readwrite, strong) NSString *album;

@end

@implementation LastFmTrack

- (id) initWithJSON:(NSDictionary *)json
{
    self = [super init];
    if( self)
        [self parseJSON:json];
    return self;
}

- (void) parseJSON:(NSDictionary *)json
{
    //  RootKeyimage
    if( [json[ RootKeyimage] isKindOfClass:[NSURL class]])
        self.image = [json[ RootKeyimage] absoluteString];
    
    //  RootKeyname
    if( [json[ RootKeyname] isKindOfClass:[NSString class]])
        self.name = json[ RootKeyname];
    
    //  RootKeyplaycount
    if( [json[ RootKeyplaycount] isKindOfClass:[NSNumber class]])
        self.playcount = json[ RootKeyplaycount];
    
    //  RootKeyplaycount
    if( [json[ RootKeyplayDate] isKindOfClass:[NSDate class]])
        self.date = json[ RootKeyplayDate];
    
    //  RootKeyplaycount
    if( [json[ RootKeyplayArtist] isKindOfClass:[NSString class]])
        self.artist = json[ RootKeyplayArtist];
    
    //  RootKeyplaycount
    if( [json[ RootKeyplayAlbum] isKindOfClass:[NSString class]])
        self.album = json[ RootKeyplayAlbum];
    
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"<Root: image = %@, name = %@, playcount = %@>", self.image, self.name, self.playcount];
}


@end
