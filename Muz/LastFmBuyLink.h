//
//  LastFmBuyLink.h
//  Muz
//
//  Created by Nick Lanasa on 12/16/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LastFmBuyLink : NSObject

@property (nonatomic, readonly, strong) NSString *currency;
@property (nonatomic, readonly, strong) NSURL *icon;
@property (nonatomic, readonly, strong) NSString *name;
@property (nonatomic, readonly, strong) NSNumber *price;
@property (nonatomic, readonly, strong) NSURL *url;

- (id) initWithJSON:(NSDictionary *)json;
- (void) parseJSON:(NSDictionary *)json;
- (NSString *) description;


@end
