//
//  SiteList+Extensions.swift
//  Chinook_Example
//
//  Created by Gary Kash on 2020-02-16.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Chinook

extension SiteList {
    func snag(someRandomSites numberOfRandomSites: Int) -> [Site] {
        guard numberOfRandomSites < site.count else { return site }
        
        var randomSites: [Site] = []

        while randomSites.count < numberOfRandomSites {
            let randomIndex = Int.random(in: 0 ..< site.count)
            let randomSite = site[randomIndex]
            
            if !randomSites.contains(randomSite) {
                randomSites.append(randomSite)
            }
        }
        
        return randomSites
    }
}

