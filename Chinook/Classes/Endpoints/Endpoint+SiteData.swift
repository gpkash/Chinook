//
//  Endpoint+SiteData.swift
//  Chinook
//
//  Created by Gary Kash on 2020-02-22.
//

import Foundation

extension Endpoint {
    public static func cityPageWeather(forSite site: Site) -> Endpoint {
        let languageComponent = NSLocale.isFrench ? "f" : "e"
        let path = "/citypage_weather/xml/\(site.provinceCode.uppercased())/\(site.code)_\(languageComponent).xml"

        return Endpoint(host: .datamart, path: path)
    }
}
