//
//  Endpoint+SiteData.swift
//  Chinook
//
//  Created by Gary Kash on 2020-02-22.
//

import Foundation

extension Endpoint {
    public static func cityPageWeather(forSite site: Site) -> Endpoint {
        let codeAffix = NSLocale.isFrench ? "_f" : "_e"
        let path = "/citypage_weather/xml/\(site.provinceCode)/\(site.code)\(codeAffix).xml"

        return Endpoint(host: .datamart, path: path)
    }
}
