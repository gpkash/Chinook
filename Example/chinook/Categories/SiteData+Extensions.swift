//
//  SiteData+Extensions.swift
//  Chinook_Example
//
//  Created by Gary Kash on 2020-02-16.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Chinook

extension SiteData {
    var friendlyName: String {
        return "\(location.name.value), \(location.province)"
    }
}
