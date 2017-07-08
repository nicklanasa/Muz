//
//  LastFmRequest.swift
//  Muz
//
//  Created by Nick Lanasa on 12/14/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation

class LastFmRequest: WebRequest {
    
    var apiKey = "d55a72556285ca314e7af8b0fb093e29"
    var apiSecret = "affa81f90053b2114888298f3aeb27b9"
    
    override func sendURLRequest() {
        super.sendURLRequest()
    }
    
    override func connectionDidFinishLoading(_ connection: NSURLConnection) {
        super.connectionDidFinishLoading(connection)
    }
    
}
