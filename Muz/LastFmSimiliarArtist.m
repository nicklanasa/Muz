//
//  LastFmSimiliarArtist.m
//  Muz
//
//  Created by Nick Lanasa on 12/14/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

#import "LastFmSimiliarArtist.h"
#import "LastFmArtist.h"

static NSString * const similarKeyartist = @"artist";


@interface LastFmSimiliarArtist ()

@property (nonatomic, readwrite, strong) NSArray *artists;

@end

@implementation LastFmSimiliarArtist

- (id) initWithJSON:(NSDictionary *)json
{
    self = [super init];
    if( self)
        [self parseJSON:json];
    return self;
}

- (void) parseJSON:(NSDictionary *)json
{
    //  similarKeyartist
    if( [json[ similarKeyartist] isKindOfClass:[NSArray class]])
    {
        NSMutableArray *artistsArray = [NSMutableArray array];
        for( id artist in json[ similarKeyartist])
            if( [artist isKindOfClass:[NSDictionary class]])
                [artistsArray addObject:[[LastFmArtist alloc] initWithJSON:artist]];
        self.artists = [NSArray arrayWithArray:artistsArray];
    }
    
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"<similar: artist = %@>", self.artists];
}


@end
