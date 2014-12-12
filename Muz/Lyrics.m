//
//  Lyrics.m
//  gMuz
//
//  Created by Nick Lanasa on 10/26/13.
//  Copyright (c) 2013 Tom Adriaenssen. All rights reserved.
//

#import "Lyrics.h"
#import "HTMLParser.h"

@implementation Lyrics

- (NSString *)getLyricsForSong {
    
//    NSString *path = [[NSString stringWithFormat:@"http://search.azlyrics.com/search.php?q=%@ %@", song.artist, song.name] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
        NSString *path = [[NSString stringWithFormat:@"http://search.azlyrics.com/search.php?q=%@ %@"] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:path]];
    NSURLResponse *r = [[NSURLResponse alloc] init];
    NSError *e;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&r error:&e];
    NSString *html = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    HTMLParser *parser = [[HTMLParser alloc] initWithString:html error:&e];
    
    if (e) {
        NSLog(@"Error: %@", e);
        return @"";
    }
    
//    HTMLNode *bodyNode = [parser body];
//    
//    NSArray *inputNodes = [bodyNode findChildTags:@"div"];
//    
//    for (HTMLNode *inputNode in inputNodes) {
//        if ([[inputNode getAttributeNamed:@"class"] isEqualToString:@"sen"]) {
//            
//            NSArray *inputANodes = [inputNode findChildTags:@"a"];
//            
//            for (HTMLNode *aNodes in inputANodes) {
//                // Check content for song name
//                if ([aNodes.contents rangeOfString:song.title options:NSCaseInsensitiveSearch].location != NSNotFound) {
//                    //NSLog(@"%@", [aNodes getAttributeNamed:@"href"]); //Answer to first question
//                    
//                    path = [[aNodes getAttributeNamed:@"href"] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
//                    request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:path]];
//                    r = [[NSURLResponse alloc] init];
//                    data = [NSURLConnection sendSynchronousRequest:request returningResponse:&r error:&e];
//                    html = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//                    
//                    parser = [[HTMLParser alloc] initWithString:html error:&e];
//                    bodyNode = [parser body];
//                    
//                    NSArray *inputDivNodes = [bodyNode findChildTags:@"div"];
//                    
//                    for (HTMLNode *divNodes in inputDivNodes) {
//                        NSArray *divTags = [divNodes findChildTags:@"div"];
//                        
//                        for (HTMLNode *dNodes in divTags) {
//                            if ([dNodes.rawContents rangeOfString:@"<!-- start of lyrics -->" options:NSCaseInsensitiveSearch].location != NSNotFound) {
//                                NSString *lyrics = dNodes.rawContents;
//                                lyrics = [lyrics stringByReplacingOccurrencesOfString:@"<!-- start of lyrics -->" withString:@""];
//                                lyrics = [lyrics stringByReplacingOccurrencesOfString:@"<!-- end of lyrics -->" withString:@""];
//                                lyrics = [lyrics stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
//                                return lyrics;
//                            }
//                        }
//                    }
//                }
//            }
//        }
//    }
//    
    return nil;
    
}

@end
