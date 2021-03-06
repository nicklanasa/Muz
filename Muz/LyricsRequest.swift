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
    func lyricsRequestDidComplete(_ request: LyricsRequest, didCompleteWithLyrics lyrics: String?)
}

class LyricsRequest: WebRequest {
    
    let url: URL?
    let item: MPMediaItem?
    var delegate: LyricsRequestDelegate?
    
    var responseData = NSMutableData()
    
    init(url: URL, item: MPMediaItem) {
        self.url = url
        self.item = item
    }
    
    override func sendURLRequest() {
        super.sendURLRequest()
        let request = URLRequest(url: self.url!)
        let connection = NSURLConnection(request: request, delegate: self)
        connection?.start()
    }
    
    func connection(_ connection: NSURLConnection, didReceiveData data: Data) {
        responseData.append(data)
    }
    
    override func connectionDidFinishLoading(_ connection: NSURLConnection) {
        super.connectionDidFinishLoading(connection)
        
        if responseData.length > 0 {
            if let html = NSString(data: responseData as Data, encoding: String.Encoding.utf8.rawValue) {
                self.parseHTML(html)
            } else {
                self.delegate?.lyricsRequestDidComplete(self, didCompleteWithLyrics: nil)
            }
        }
    }
    
    // Lyric parsing
    
    fileprivate func parseHTML(_ html: NSString) {
//        let parser: HTMLParser!
//        do {
//            parser = try HTMLParser(string: html as String)
//        } catch {}
//        
//        for inputNode in parser.body().findChildTags("div") {
//            if let attribute = inputNode.getAttributeNamed("class") {
//                if attribute == "sen" {
//                    for aNodes in inputNode.findChildTags("a") as! [HTMLNode] {
//                        if let contents = aNodes.contents {
//                            let range = contents.rangeOfString(item!.title, options: .CaseInsensitiveSearch)
//                            
//                            if range.location != NSNotFound {
//                                let url = aNodes.getAttributeNamed("href") as String
//                                self.requestSongLyrics(url)
//                                return
//                            }
//                        }
//                    }
//                }
//            }
//        }
//        
//        self.delegate?.lyricsRequestDidComplete(self, didCompleteWithLyrics: nil)
    }
    
    fileprivate func requestSongLyrics(_ url: NSString) {
        
//        var lyrics: String? = nil
//        if let stringURL = url.stringByAddingPercentEscapesUsingEncoding(NSASCIIStringEncoding) {
//            let url = NSURL(string: stringURL)!
//            let request = NSURLRequest(URL: url)
//            let queue = NSOperationQueue()
//            var response: NSURLResponse?
//            var error: NSError?
//            
//            NSURLConnection.sendAsynchronousRequest(request, queue: queue, completionHandler: { (response, data, error) -> Void in
//                if let html = NSString(data: data, encoding: NSUTF8StringEncoding) {
//                    var parserError: NSError?
//                    let parser = HTMLParser(string: html as String, error: &parserError)
//                    var body = parser.body().findChildTags("div")
//                    for divNodes in body {
//                        for dNodes in divNodes.findChildTags("div") {
//                            let contents: String = dNodes.rawContents()
//                            if contents.rangeOfString("<!-- start of lyrics -->", options: .CaseInsensitiveSearch).location != NSNotFound {
//                                lyrics = contents.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
//                                lyrics = lyrics!.stringByStrippingHTML()
//                                lyrics = lyrics!.stringByReplacingOccurrencesOfString("<!-- start of lyrics -->", withString: "")
//                                lyrics = lyrics!.stringByReplacingOccurrencesOfString("<!-- end of lyrics -->", withString: "")
//                                
//                                self.delegate?.lyricsRequestDidComplete(self, didCompleteWithLyrics: lyrics)
//                                
//                                LocalyticsSession.shared().tagEvent("Lyrics found.")
//                                
//                                return
//                            }
//                        }
//                    }
//                }
//                
//                LocalyticsSession.shared().tagEvent("Lyrics not found.")
//                
//                self.delegate?.lyricsRequestDidComplete(self, didCompleteWithLyrics: lyrics)
//            })
//        }
    }
}
