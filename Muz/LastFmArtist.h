//
//  LastFmArtist.h
//  Muz
//
//  Created by Nick Lanasa on 12/14/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LastFmArtistImage;

@interface LastFmArtist : NSObject

@property (nonatomic, readonly, strong) NSString *name;
@property (nonatomic, readonly, strong) NSURL *artistURL;
@property (nonatomic, readonly, strong) NSURL *imageURL;
@property (nonatomic, readonly, strong) NSString *bio;
@property (nonatomic, readonly, strong) NSString *summary;
@property (nonatomic, readonly, strong) NSNumber *listeners;
@property (nonatomic, readonly, strong) NSNumber *plays;
@property (nonatomic, readonly, strong) NSNumber *onTour;


- (id)initWithJSON:(NSDictionary *)json;
- (void)parseJSON:(NSDictionary *)json;
- (NSString *)description;

@end
