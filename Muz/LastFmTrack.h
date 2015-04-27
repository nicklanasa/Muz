//
//  LastFmTrack.h
//  Muz
//
//  Created by Nick Lanasa on 2/9/15.
//  Copyright (c) 2015 Nytek Productions. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LastFmTrack : NSObject

@property (nonatomic, readonly, strong) NSString *image;
@property (nonatomic, readonly, strong) NSString *name;
@property (nonatomic, readonly, strong) NSNumber *playcount;
@property (nonatomic, readonly, strong) NSDate *date;
@property (nonatomic, readonly, strong) NSString *artist;
@property (nonatomic, readonly, strong) NSString *album;

- (id) initWithJSON:(NSDictionary *)json;
- (void) parseJSON:(NSDictionary *)json;
- (NSString *) description;


@end
