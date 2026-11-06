//
//  ClimateRepository.swift
//  Chinook
//
//  Created by Gary Kash on 2026-11-05.
//  Copyright © 2026 Gary Kash. All rights reserved.
//

import Foundation

public enum ClimateError: Error, Equatable {
    /// EC keeps no temperature records for this site. Not every site has them.
    case noRecordStation(siteCode: String)

    /// No station that reported daily observations in `year` is near the site.
    case noClimateStation(siteName: String, year: Int)
}

public enum ClimateRepository {
    /// Fetch the list of cities EC keeps temperature records for.
    /// - Parameter strategy: Loading strategy (disk/network behavior).
    public static func fetchRecordStations(strategy: DataLoaderStrategy) async throws -> ClimateRecordStations {
        try await fetchRecordStations(strategy: strategy, loader: .shared)
    }

    /// Fetch a site's temperature records for every day of the year.
    ///
    /// Works for any site EC keeps records for. Look up a day with `TemperatureRecords.records(on:)`.
    /// - Parameters:
    ///   - site: The Environment Canada site descriptor.
    ///   - strategy: Loading strategy (disk/network behavior).
    /// - Throws: `ClimateError.noRecordStation` if EC has no records for `site`.
    public static func fetchTemperatureRecords(forSite site: Site, strategy: DataLoaderStrategy) async throws -> TemperatureRecords {
        try await fetchTemperatureRecords(forSite: site, strategy: strategy, loader: .shared)
    }

    /// Fetch the list of climate stations.
    /// - Parameter strategy: Loading strategy (disk/network behavior).
    public static func fetchClimateStations(strategy: DataLoaderStrategy) async throws -> ClimateStations {
        try await fetchClimateStations(strategy: strategy, loader: .shared)
    }

    /// Fetch the station that observed the weather for a site in a given year.
    ///
    /// A site's station changes over the years (Winnipeg's airport is `5023222` until 2008 and `5023227` since 2018),
    /// so the year is part of the question. Use `ClimateStation.climateID` and `province` to name that year's observations.
    /// - Parameters:
    ///   - siteData: The site's city page, which says where it and its observing station are.
    ///   - year: The calendar year to find a station for.
    ///   - strategy: Loading strategy (disk/network behavior).
    /// - Throws: `ClimateError.noClimateStation` if no station near the site reported daily observations in `year`.
    public static func fetchClimateStation(forSiteData siteData: SiteData, year: Int, strategy: DataLoaderStrategy) async throws -> ClimateStation {
        try await fetchClimateStation(forSiteData: siteData, year: year, strategy: strategy, loader: .shared)
    }

    /// Fetch how a calendar month went at a site's station, next to the 1981–2010 normals for that month.
    ///
    /// The daily file for the current year grows every day, so for a month that has just ended pass `.networkOnly`
    /// to get all of it. The station list and normals change rarely and are always read from disk first.
    /// - Parameters:
    ///   - siteData: The site's city page, which says where it and its observing station are.
    ///   - year: The calendar year of the month.
    ///   - month: The month, 1 to 12.
    ///   - strategy: Loading strategy for the daily observations (disk/network behavior).
    /// - Throws: `ClimateError.noClimateStation` if no station near the site reported daily observations in `year`.
    ///   Normals are optional: the summary's `normals` is nil when EC publishes none near the site.
    public static func fetchMonthlySummary(forSiteData siteData: SiteData, year: Int, month: Int, strategy: DataLoaderStrategy) async throws -> MonthlyClimateSummary {
        try await fetchMonthlySummary(forSiteData: siteData, year: year, month: month, strategy: strategy, loader: .shared)
    }
}

// MARK: - Implementation (loader injectable)

extension ClimateRepository {
    static func fetchRecordStations(strategy: DataLoaderStrategy, loader: DataLoader) async throws -> ClimateRecordStations {
        try Task.checkCancellation()

        let response = try await loader.request(.climateRecordStations, strategy: strategy)

        try Task.checkCancellation()

        return ClimateRecordStations(csv: response.data)
    }

    static func fetchClimateStations(strategy: DataLoaderStrategy, loader: DataLoader) async throws -> ClimateStations {
        try Task.checkCancellation()

        let response = try await loader.request(.climateStationList(language: .english), strategy: strategy)

        try Task.checkCancellation()

        return ClimateStations(csv: response.data)
    }

    static func fetchClimateStation(forSiteData siteData: SiteData, year: Int, strategy: DataLoaderStrategy, loader: DataLoader) async throws -> ClimateStation {
        let stations = try await fetchClimateStations(strategy: strategy, loader: loader)

        guard let station = stations.station(for: siteData, year: year) else {
            throw ClimateError.noClimateStation(siteName: siteData.location.name.value ?? "", year: year)
        }

        return station
    }

    static func fetchTemperatureRecords(forSite site: Site, strategy: DataLoaderStrategy, loader: DataLoader) async throws -> TemperatureRecords {
        let stations = try await fetchRecordStations(strategy: strategy, loader: loader)

        guard let station = stations.station(for: site) else {
            throw ClimateError.noRecordStation(siteCode: site.code)
        }

        let endpoint = Endpoint.climateRecords(province: station.province, virtualClimateID: station.virtualClimateID)
        let response = try await loader.request(endpoint, strategy: strategy)

        try Task.checkCancellation()

        return TemperatureRecords(csv: response.data, station: station)
    }

    static func fetchMonthlySummary(forSiteData siteData: SiteData, year: Int, month: Int, strategy: DataLoaderStrategy, loader: DataLoader) async throws -> MonthlyClimateSummary {
        let slowChanging: DataLoaderStrategy = strategy == .diskOnly ? .diskOnly : .diskWithNetworkFallback
        let stations = try await fetchClimateStations(strategy: slowChanging, loader: loader)

        guard let station = stations.station(for: siteData, year: year) else {
            throw ClimateError.noClimateStation(siteName: siteData.location.name.value ?? "", year: year)
        }

        let daily = try await loader.request(.climateDaily(province: station.province, climateID: station.climateID, year: year), strategy: strategy)

        try Task.checkCancellation()

        let normals = try await fetchNormals(forMonth: month, near: stations.normalsStations(for: siteData), strategy: slowChanging, loader: loader)

        return MonthlyClimateSummary(station: station, year: year, month: month, observations: DailyObservations(csv: daily.data), normals: normals)
    }

    /// The first of `candidates` EC has a normals file for. A missing file isn't an error, since the station list can't say for sure which exist.
    private static func fetchNormals(forMonth month: Int, near candidates: [ClimateStation], strategy: DataLoaderStrategy, loader: DataLoader) async throws -> MonthlyNormals? {
        for candidate in candidates {
            try Task.checkCancellation()

            do {
                let response = try await loader.request(.climateNormals(province: candidate.province, climateID: candidate.climateID), strategy: strategy)
                return ClimateNormals(csv: response.data).normals(forMonth: month)
            }
            catch NetworkError.httpError(let statusCode) where statusCode == 404 {
                continue
            }
            catch DataLoaderError.notCached {
                continue
            }
        }

        return nil
    }
}
