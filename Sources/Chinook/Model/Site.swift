//
//  Site.swift
//  Chinook
//
//  Created by Gary Kash on 2020-02-01.
//  Copyright © 2020 Gary Kash. All rights reserved.
//

import Foundation

public struct Site: XMLDecodable, Hashable {
    public let code: String
    public let nameEn: String
    public let nameFr: String
    public let provinceCode: String
    
    public init(code: String, nameEn: String, nameFr: String, provinceCode: String) {
        self.code = code
        self.nameEn = nameEn
        self.nameFr = nameFr
        self.provinceCode = provinceCode
    }
}

public extension Site {
    /// Returns either `nameEn` or `nameFr` depending on the locale of the system.
    var name: String {
        return NSLocale.language == .french ? nameFr : nameEn
    }
}

extension Site: Equatable {
    /// Environment Canada gives each site a code. This assumes these codes will remain unique.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.code == rhs.code
    }
}

public extension Site {
    enum SiteDataUpdatedNotificationKeys: String {
        case site
        case siteData
    }
    
    var siteDataUpdatedNotification: NSNotification.Name {
        NSNotification.Name("com.thefloorislava.retroweather.Site.SiteDataUpdated\(code)")
    }
}

