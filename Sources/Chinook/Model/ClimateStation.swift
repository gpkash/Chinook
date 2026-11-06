//
//  ClimateStation.swift
//  Chinook
//
//  Created by Gary Kash on 2026-11-05.
//

import Foundation

/// A place EC has measured the weather, identified by its Climate ID. Daily observation files are keyed by it.
///
/// Stations come and go, and a city's airport is often replaced by a new station with a new ID, so the one
/// to ask for depends on the year: see `ClimateStations.station(for:year:)`.
public struct ClimateStation: Hashable, Sendable {
    /// The ID daily observation files are named after, e.g. `5023227`.
    public let climateID: String
    public let name: String
    public let province: Province
    public let latitude: Double
    public let longitude: Double
    /// The first to last year the station reported daily observations, if it ever did. Years inside the range can still be missing.
    public let dailyYears: ClosedRange<Int>?
    /// The first to last year the station reported monthly summaries, if it ever did. Climate normals are built from these.
    public let monthlyYears: ClosedRange<Int>?

    public init(climateID: String, name: String, province: Province, latitude: Double, longitude: Double, dailyYears: ClosedRange<Int>?, monthlyYears: ClosedRange<Int>? = nil) {
        self.climateID = climateID
        self.name = name
        self.province = province
        self.latitude = latitude
        self.longitude = longitude
        self.dailyYears = dailyYears
        self.monthlyYears = monthlyYears
    }

    public func reportsDaily(in year: Int) -> Bool {
        dailyYears?.contains(year) ?? false
    }

    /// Whether the station reported long enough in 1981–2010 for EC to have published normals for it.
    ///
    /// EC wants at least 15 years of monthly data. This is a guess from the station list, not a promise: a file can still be missing.
    var likelyHasNormals: Bool {
        guard let monthlyYears else { return false }

        let overlap = min(monthlyYears.upperBound, ClimateNormals.lastYear) - max(monthlyYears.lowerBound, ClimateNormals.firstYear) + 1
        return overlap >= 15
    }

    /// Great-circle distance to a point, in kilometres.
    func kilometres(fromLatitude latitude: Double, longitude: Double) -> Double {
        let earthRadius = 6371.0
        let latitudeDelta = (latitude - self.latitude) * .pi / 180
        let longitudeDelta = (longitude - self.longitude) * .pi / 180
        let a = pow(sin(latitudeDelta / 2), 2)
            + cos(self.latitude * .pi / 180) * cos(latitude * .pi / 180) * pow(sin(longitudeDelta / 2), 2)

        return 2 * earthRadius * asin(min(1, a.squareRoot()))
    }
}

/// Every climate station EC lists, and the way from a site and a year to the station that observed it.
public struct ClimateStations: Sendable {
    public let stations: [ClimateStation]

    /// Reads `Endpoint.climateStationList(language: .english)`. Rows without a known province or a position are skipped.
    public init(csv data: Data) {
        stations = CSVTable(data: data).rows.compactMap { row in
            guard let climateID = row["Climate ID"],
                  let name = row["Station Name"],
                  let province = row["Province"].flatMap({ Self.provincesByName[$0.uppercased()] }),
                  let latitude = row["Latitude"].flatMap({ Double($0) }),
                  let longitude = row["Longitude"].flatMap({ Double($0) })
            else { return nil }

            let dailyYears = Self.years(row, first: "DLY First Year", last: "DLY Last Year")
            let monthlyYears = Self.years(row, first: "MLY First Year", last: "MLY Last Year")

            return ClimateStation(climateID: climateID, name: name, province: province, latitude: latitude, longitude: longitude, dailyYears: dailyYears, monthlyYears: monthlyYears)
        }
    }

    /// The station nearest to a point that reported daily observations in `year`, or nil if none is within `maxKilometres`.
    public func station(nearLatitude latitude: Double, longitude: Double, year: Int, maxKilometres: Double = 25) -> ClimateStation? {
        stations
            .filter { $0.reportsDaily(in: year) }
            .map { (station: $0, distance: $0.kilometres(fromLatitude: latitude, longitude: longitude)) }
            .filter { $0.distance <= maxKilometres }
            .min { $0.distance < $1.distance }?
            .station
    }

    /// The station that observed the weather for `siteData` in `year`.
    ///
    /// It looks near the station that measures the site's current conditions, since that's the one people mean by
    /// "the weather in Winnipeg" (the airport), and near the site itself when no station is reporting.
    public func station(for siteData: SiteData, year: Int, maxKilometres: Double = 25) -> ClimateStation? {
        guard let point = siteData.observationPoint ?? siteData.point else { return nil }

        return station(nearLatitude: point.y, longitude: point.x, year: year, maxKilometres: maxKilometres)
    }

    /// Stations near a site that probably have climate normals, nearest first. The nearest is often not the one with a file
    /// (Winnipeg's airport is `5023227` today, but its normals were built from `5023222`), so callers try them in order.
    public func normalsStations(for siteData: SiteData, maxKilometres: Double = 25, limit: Int = 3) -> [ClimateStation] {
        guard let point = siteData.observationPoint ?? siteData.point else { return [] }

        return stations
            .filter(\.likelyHasNormals)
            .map { (station: $0, distance: $0.kilometres(fromLatitude: point.y, longitude: point.x)) }
            .filter { $0.distance <= maxKilometres }
            .sorted { $0.distance < $1.distance }
            .prefix(limit)
            .map(\.station)
    }

    private static func years(_ row: CSVTable.Row, first: String, last: String) -> ClosedRange<Int>? {
        row[first].flatMap { Int($0) }.flatMap { first in
            row[last].flatMap { Int($0) }.flatMap { last in first <= last ? first...last : nil }
        }
    }

    /// The station list names provinces in full, in capitals: "NEWFOUNDLAND AND LABRADOR".
    private static let provincesByName: [String: Province] = Dictionary(
        Province.lookupTable.values.map { ($0.nameEn.uppercased(), $0) },
        uniquingKeysWith: { first, _ in first }
    )
}
