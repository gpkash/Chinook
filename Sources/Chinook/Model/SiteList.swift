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
        sitesByProvince(in: NSLocale.language)
    }

    /// The sites grouped by province, each group sorted by the site's name in `language`
    /// (locale-aware, so "Île-…" sorts with I, not after Z).
    public func sitesByProvince(in language: Language) -> [Province : [Site]] {
        // Build buckets without repeated sorts (O(n)), then sort once per province (O(k · m log m)).
        var sitesByProvince: [Province: [Site]] = [:]
        sitesByProvince.reserveCapacity(Province.count)
        for site in sites {
            guard let province = Province.forCode(site.provinceCode) else { continue }
            sitesByProvince[province, default: []].append(site)
        }

        for (province, sites) in sitesByProvince {
            sitesByProvince[province] = sites.sorted { $0.name(in: language).localizedStandardCompare($1.name(in: language)) == .orderedAscending }
        }

        return sitesByProvince
    }
}
