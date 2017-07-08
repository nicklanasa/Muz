//
//  WebRequest.swift
//  Muz
//
//  Created by Nick Lanasa on 12/23/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation

class WebRequest: NSObject, NSURLConnectionDataDelegate, NSURLConnectionDelegate {
    func sendURLRequest() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func connectionDidFinishLoading(_ connection: NSURLConnection) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}
