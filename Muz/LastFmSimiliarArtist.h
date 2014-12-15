//
//  LastFmSimiliarArtist.h
//  Muz
//
//  Created by Nick Lanasa on 12/14/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LastFmArtist;

@interface LastFmSimiliarArtist : NSObject

@property (nonatomic, readonly, strong) NSArray *artists;

- (id) initWithJSON:(NSDictionary *)json;
- (void) parseJSON:(NSDictionary *)json;
- (NSString *) description;


@end
