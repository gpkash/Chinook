//
//  Endpoint+SiteData.swift
//  Chinook
//
//  Created by Gary Kash on 2020-02-22.
//

import Foundation

extension Endpoint {
    /// The newest city page file for `site`, found by searching EC's hourly directories.
    public static func latestCityPageWeather(forSite site: Site) async throws -> Endpoint {
        try await CityPageLocator.shared.latestEndpoint(for: site, language: NSLocale.language)
    }
}
