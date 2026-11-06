//
//  Endpoint+Climate.swift
//  Chinook
//
//  Created by Gary Kash on 2026-11-05.
//

import Foundation

/// Climate data on Datamart: observed days, normals and long-term extremes (records). All of it is CSV.
///
/// Files are keyed by province and by a station ID, and the two kinds of ID are not interchangeable:
/// a *Climate ID* names an observing station (`5023227`), a *virtual climate ID* names a city's
/// record series (`VSMB38V`). A station can also be replaced by a new ID when it moves or is
/// re-instrumented (Winnipeg's `5023222` stops in 2008, `5023227` carries on), so look IDs up in
/// `climateStationList(language:)` rather than hard-coding them.
extension Endpoint {
    // MARK: - Stations

    /// Every climate station, with its Climate ID and the years it reported. Use it to find which ID has data for a given year.
    public static func climateStationList(language: Language) -> Endpoint {
        let filename = language.pick(en: "climate_station_list.csv", fr: "climate_station_list_fre.csv")
        return Endpoint(host: .datamart, path: "/today/climate/observations/\(filename)")
    }

    /// Every city with a record series, and the stations whose data it is built from.
    public static let climateRecordStations = Endpoint(host: .datamart, path: "/today/climate/ltce/stations/climate_LTCE_Temperature_Virtual-Stations.csv")

    // MARK: - Observations

    /// One station's daily observations (max, min and mean temperature, precipitation, ...) for a calendar year.
    ///
    /// The file for the current year grows daily, so load it with `.networkOnly`; past years never change.
    /// - Parameters:
    ///   - province: The province or territory the station is in.
    ///   - climateID: The station's Climate ID, e.g. `5023227`.
    ///   - year: The calendar year, e.g. `2025`.
    public static func climateDaily(province: Province, climateID: String, year: Int) -> Endpoint {
        let code = province.abbreviation.uppercased()
        return Endpoint(host: .datamart, path: "/today/climate/observations/daily/csv/\(code)/climate_daily_\(code)_\(climateID)_\(year)_P1D.csv")
    }

    // MARK: - Normals

    /// One station's 1981–2010 climate normals. Values are by month, not by day.
    /// - Parameters:
    ///   - province: The province or territory the station is in.
    ///   - climateID: The station's Climate ID, e.g. `5023222`.
    public static func climateNormals(province: Province, climateID: String) -> Endpoint {
        let code = province.abbreviation.uppercased()
        return Endpoint(host: .datamart, path: "/today/climate/observations/normals/csv/1981-2010/\(code)/climate_normals_\(code)_\(climateID)_1981-2010.csv")
    }

    // MARK: - Records

    /// A city's daily temperature records: one row per calendar day, with the record high and low, the year each was set, and the record they replaced.
    ///
    /// The file reflects records as they stand today, so it changes whenever one is broken.
    /// - Parameters:
    ///   - province: The province or territory the city is in.
    ///   - virtualClimateID: The city's virtual climate ID, e.g. `VSMB38V` for Winnipeg (see `climateRecordStations`).
    public static func climateRecords(province: Province, virtualClimateID: String) -> Endpoint {
        let code = province.abbreviation.uppercased()
        return Endpoint(host: .datamart, path: "/today/climate/ltce/daily/temperature/\(code)/climate_LTCE_Temperature-Records_\(code)_\(virtualClimateID).csv")
    }
}
