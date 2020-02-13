//
//  Host.swift
//  Chinook
//
//  Created by Gary Kash on 2020-02-01.
//  Copyright © 2020 Gary Kash. All rights reserved.
//

import Foundation

struct Host {
    let scheme: String
    let hostname: String
    
    init(scheme: String = "http", hostname: String) {
        self.scheme = scheme
        self.hostname = hostname
    }
}
