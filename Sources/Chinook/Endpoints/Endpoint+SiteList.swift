//
//  Endpoint+SiteList.swift
//  Chinook
//
//  Created by Gary Kash on 2020-02-22.
//

import Foundation

extension Endpoint {
    @MainActor public static let citypageWeatherSiteList = Endpoint(host: .datamart, path: "/today/citypage_weather/siteList.xml")
}
