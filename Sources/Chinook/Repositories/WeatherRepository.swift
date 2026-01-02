//
//  WeatherRepository.swift
//  Chinook
//
//  Created by Gary Kash on 2025-10-18.
//  Copyright © 2025 Gary Kash. All rights reserved.
//

import Foundation

public enum WeatherRepository {
    public enum Notifications {
        public static let siteListUpdated = Notification.Name(rawValue: "com.thefloorislava.retroweather.WeatherRepository.siteListUpdated")
        public static let observationCollectionUpdated = Notification.Name(rawValue: "com.thefloorislava.retroweather.WeatherRepository.observationCollectionUpdated")
    }

    /// Fetch the latest City Page weather `SiteData` for a given site.
    /// - Parameters:
    ///   - site: The Environment Canada site descriptor.
    ///   - strategy: Loading strategy (disk/network behavior).
    /// - Returns: Decoded `SiteData` for the site’s current conditions.
    @discardableResult
    public static func fetchWeather(forSite site: Site, strategy: DataLoaderStrategy) async throws -> SiteData {
        // Cooperative cancellation before and after network work
        try Task.checkCancellation()

        // Endpoint discovery (appears to be async in your codebase)
        let endpoint = try await Endpoint.latestCityPageWeather(forSite: site)

        // Fetch via static DataLoader facade
        let responseData = try await DataLoader.request(endpoint, strategy: strategy).data

        try Task.checkCancellation()
        
        let siteData = try SiteData.decode(fromXML: responseData)

        NotificationCenter.default.post(name: site.siteDataUpdatedNotification, object: siteData)

        return siteData
    }
    
    /// Fetch the latest City Page weather `SiteData` for multiple sites in parallel.
    /// - Parameters:
    ///   - sites: The Environment Canada site descriptors.
    ///   - strategy: Loading strategy (disk/network behavior).
    /// - Returns: An array of decoded `SiteData` for each site’s current conditions, preserving the input order for successful sites. Individual failures do not cancel other loads and are omitted from the result. If all sites fail, the first encountered error is thrown.
    @discardableResult
    public static func fetchWeather(forSites sites: [Site], strategy: DataLoaderStrategy) async throws -> [SiteData] {
        // Fast-path: nothing to do
        guard !sites.isEmpty else { return [] }

        try Task.checkCancellation()

        // Run all site fetches concurrently, but ensure single failures don't cancel other loads.
        let (successes, firstError) = await withTaskGroup(of: (Int, Result<SiteData, Error>).self, returning: ([SiteData], Error?).self) { group in
            // Spawn child tasks that never throw; they report success/failure via Result.
            for (index, site) in sites.enumerated() {
                group.addTask {
                    // Cooperatively respect cancellation without throwing from the child.
                    if Task.isCancelled {
                        return (index, .failure(CancellationError()))
                    }

                    do {
                        let data = try await fetchWeather(forSite: site, strategy: strategy)
                        return (index, .success(data))
                    } catch {
                        // Capture individual site failure without throwing to the group.
                        return (index, .failure(error))
                    }
                }
            }

            // Collect results into an order-preserving buffer, skipping failures.
            var ordered = Array<SiteData?>(repeating: nil, count: sites.count)
            var firstError: Error?

            for await (index, result) in group {
                switch result {
                case .success(let data):
                    ordered[index] = data
                case .failure(let error):
                    if firstError == nil { firstError = error }
                }
            }

            let successes = ordered.compactMap { $0 }
            return (successes, firstError)
        }
        
        try Task.checkCancellation()
        
        if successes.isEmpty, let error = firstError {
            throw error
        }
        return successes
    }
    
    /// Fetch the `ObservationCollection` for the specified province.
    /// - Parameters:
    ///   - provinceCode: The province code.
    ///   - strategy: The data loading strategy to use.
    /// - Returns: A decoded `ObservationCollection`.
    public static func fetchObservationCollection(
        forProvince provinceCode: String,
        strategy: DataLoaderStrategy
    ) async throws -> ObservationCollection {
        try Task.checkCancellation()

        let endpoint = Endpoint.observationCollection(forProvinceWithCode: provinceCode)
        let response = try await DataLoader.request(endpoint, strategy: strategy)

        try Task.checkCancellation()
        
        let observationCollection = try ObservationCollection.decode(
            fromXML: response.data,
            keyDecodingStrategy: .observationCollectionCustomStrategy
        )
        
        NotificationCenter.default.post(name: Notifications.observationCollectionUpdated, object: observationCollection)
        
        return observationCollection
    }
    
    /// Fetch the Environment Canada City Page weather site list.
    /// - Parameter strategy: Loading strategy (disk/network behavior).
    /// - Returns: Decoded `SiteList`.
    @discardableResult
    public static func fetchCityPageSiteList(strategy: DataLoaderStrategy) async throws -> SiteList {
        try Task.checkCancellation()

        let response = try await DataLoader.request(.citypageWeatherSiteList, strategy: strategy)

        try Task.checkCancellation()
        
        let siteList = try SiteList.decode(fromXML: response.data)
        
        NotificationCenter.default.post(name: Notifications.siteListUpdated, object: siteList)
        
        return siteList
    }
}

extension SiteData: @unchecked Sendable { }
extension Site: @unchecked Sendable { }
extension DataLoaderStrategy: @unchecked Sendable { }

