//
//  NSString+Lyrics.m
//  Muz
//
//  Created by Nick Lanasa on 12/12/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

#import "NSString+Lyrics.h"

@implementation NSString (Lyrics)

- (NSString *)stringByStrippingHTML
{
    NSMutableString *outString;
    NSString *inputString = self;
    
    if (inputString)
    {
        outString = [[NSMutableString alloc] initWithString:inputString];
        
        if ([inputString length] > 0)
        {
            NSRange r;
            
            while ((r = [outString rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound)
            {
                [outString deleteCharactersInRange:r];
            }
        }
    }
    
    return outString;
}

@end
