//
//  WebRequest.swift
//  WebRequestSample
//
//  Created by Nick Lanasa on 12/11/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation
import MediaPlayer

protocol LyricsRequestDelegate {
    func lyricsRequestDidComplete(request: LyricsRequest, didCompleteWithLyrics lyrics: String)
}

class LyricsRequest: NSObject, NSURLConnectionDataDelegate, NSURLConnectionDelegate {
    
    let url: NSURL?
    let item: MPMediaItem?
    var delegate: LyricsRequestDelegate?
    
    var responseData = NSMutableData()
    
    init(url: NSURL, item: MPMediaItem) {
        self.url = url
        self.item = item
    }
    
    func sendURLRequest() {
        let request = NSURLRequest(URL: self.url!)
        let connection = NSURLConnection(request: request, delegate: self)
        connection?.start()
    }
    
    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        responseData.appendData(data)
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection) {
        if responseData.length > 0 {
            if let html = NSString(data: responseData, encoding: NSUTF8StringEncoding) {
                self.parseHTML(html)
            }
        }
    }
    
    // Lyric parsing
    
    private func parseHTML(html: NSString) {
        var error: NSError?
        let parser = HTMLParser(string: html, error: &error)
        
        for inputNode in parser.body().findChildTags("div") {
            if let attribute = inputNode.getAttributeNamed("class") {
                if attribute == "sen" {
                    for aNodes in inputNode.findChildTags("a") {
                        if let contents = aNodes.contents as? NSString {
                            let range = contents.rangeOfString(item!.title, options: .CaseInsensitiveSearch)
                            
                            if range.location != NSNotFound {
                                let url = aNodes.getAttributeNamed("href") as String
                                self.requestSongLyrics(url)
                                return
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func requestSongLyrics(url: NSString) {
        if let stringURL = url.stringByAddingPercentEscapesUsingEncoding(NSASCIIStringEncoding) {
            let url = NSURL(string: stringURL)!
            let request = NSURLRequest(URL: url)
            let queue = NSOperationQueue()
            var response: NSURLResponse?
            var error: NSError?
            
            if let data = NSURLConnection.sendSynchronousRequest(request, returningResponse: &response, error: &error) {
                if let html = NSString(data: data, encoding: NSUTF8StringEncoding) {
                    var parserError: NSError?
                    let parser = HTMLParser(string: html, error: &parserError)
                    var body = parser.body().findChildTags("div")
                    for divNodes in body {
                        for dNodes in divNodes.findChildTags("div") {
                            let contents: NSString = dNodes.rawContents()
                            if contents.rangeOfString("<!-- start of lyrics -->", options: .CaseInsensitiveSearch).location != NSNotFound {
                                var lyrics: NSString = contents.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                                lyrics = lyrics.stringByStrippingHTML()
                                lyrics = lyrics.stringByReplacingOccurrencesOfString("<!-- start of lyrics -->", withString: "")
                                lyrics = lyrics.stringByReplacingOccurrencesOfString("<!-- end of lyrics -->", withString: "")
                                
                                    
                                self.delegate?.lyricsRequestDidComplete(self, didCompleteWithLyrics: lyrics)
                                return
                            }
                        }
                    }
                }
            }
        }
    }
}