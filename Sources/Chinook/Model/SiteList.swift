//
//  SiteList.swift
//  Chinook
//
//  Created by Gary Kash on 2020-02-02.
//  Copyright © 2020 Gary Kash. All rights reserved.
//

import Foundation

public struct SiteList: XMLDecodable {
    private enum CodingKeys: String, CodingKey {
        case sites = "site"
    }
    
    public let sites: [Site]
    
    public var sitesByProvince: [Province : [Site]] {
        // Build buckets without repeated sorts (O(n)), then sort once per province (O(k · m log m)).
        var sitesByProvince: [Province: [Site]] = [:]
        sitesByProvince.reserveCapacity(Province.count)

        for site in sites {
            guard let province = Province.forCode(site.provinceCode) else { continue }
            sitesByProvince[province, default: []].append(site)
        }

        // Sort each province's sites once by name.
        for (province, sites) in sitesByProvince {
            sitesByProvince[province] = sites.sorted { $0.name < $1.name }
        }

        return sitesByProvince
    }
}
