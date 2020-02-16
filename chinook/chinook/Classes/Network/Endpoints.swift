//
//  Endpoints.swift
//  Chinook
//
//  Created by Gary Kash on 2020-02-01.
//  Copyright © 2020 Gary Kash. All rights reserved.
//

import Foundation

extension Endpoint {
    static let citypageWeatherSiteList = Endpoint(host: .datamart, path: "/citypage_weather/xml/siteList.xml")
    
    static func cityPageWeather(forSite site: Site) -> Endpoint {
        let codeAffix = NSLocale.isFrench ? "_f" : "_e"
        let path = "/citypage_weather/xml/\(site.provinceCode)/\(site.code)\(codeAffix).xml"

        return Endpoint(host: .datamart, path: path)
    }
}
