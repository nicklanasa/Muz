//
//  LastFmAlbum.m
//  Muz
//
//  Created by Nick Lanasa on 2/9/15.
//  Copyright (c) 2015 Nytek Productions. All rights reserved.
//

#import "LastFmAlbum.h"

static NSString * const LastFmAlbumKeyplaycount = @"playcount";
static NSString * const LastFmAlbumKeytitle = @"title";
static NSString * const LastFmAlbumKeyimage = @"image";
static NSString * const LastFmAlbumKeyurl = @"url";
static NSString * const LastFmAlbumKeyartist = @"artist";


@interface LastFmAlbum  ()

@property (nonatomic, readwrite, strong) NSNumber *playcount;
@property (nonatomic, readwrite, strong) NSString *title;
@property (nonatomic, readwrite, strong) NSString *image;
@property (nonatomic, readwrite, strong) NSString *url;
@property (nonatomic, readwrite, strong) NSString *artist;

@end


@implementation LastFmAlbum

- (id) initWithJSON:(NSDictionary *)json
{
    self = [super init];
    if( self)
        [self parseJSON:json];
    return self;
}

- (void) parseJSON:(NSDictionary *)json
{
    //  LastFmAlbumKeyplaycount
    if( [json[ LastFmAlbumKeyplaycount] isKindOfClass:[NSNumber class]])
        self.playcount = json[ LastFmAlbumKeyplaycount];
    
    //  LastFmAlbumKeytitle
    if( [json[ LastFmAlbumKeytitle] isKindOfClass:[NSString class]])
        self.title = json[ LastFmAlbumKeytitle];
    
    //  LastFmAlbumKeyimage
    if( [json[ LastFmAlbumKeyimage] isKindOfClass:[NSURL class]])
        self.image = [json[ LastFmAlbumKeyimage] absoluteString];
    
    //  LastFmAlbumKeyurl
    if( [json[ LastFmAlbumKeyurl] isKindOfClass:[NSURL class]])
        self.url = [json[ LastFmAlbumKeyurl] absoluteString];
    
    //  LastFmAlbumKeyartist
    if( [json[ LastFmAlbumKeyartist] isKindOfClass:[NSString class]])
        self.artist = json[ LastFmAlbumKeyartist];
    
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"<LastFmAlbum: playcount = %@, title = %@, image = %@, url = %@, artist = %@>", self.playcount, self.title, self.image, self.url, self.artist];
}


@end
