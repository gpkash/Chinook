//
//  ClimateRecordStation.swift
//  Chinook
//
//  Created by Gary Kash on 2026-11-05.
//

import Foundation

/// A city's temperature-record series. Environment Canada stitches it together from the station
/// (or stations) that have reported for that city over the years.
public struct ClimateRecordStation: Hashable, Sendable {
    /// The ID the records file is named after, e.g. `VSMB38V`.
    public let virtualClimateID: String
    public let province: Province
    /// EC's old city page code, e.g. `MB-38`.
    public let cityCode: String
    public let nameEn: String
    public let nameFr: String

    public init(virtualClimateID: String, province: Province, cityCode: String, nameEn: String, nameFr: String) {
        self.virtualClimateID = virtualClimateID
        self.province = province
        self.cityCode = cityCode
        self.nameEn = nameEn
        self.nameFr = nameFr
    }

    public var name: String {
        name(in: NSLocale.language)
    }

    public func name(in language: Language) -> String {
        language.pick(en: nameEn, fr: nameFr)
    }
}

/// Every city EC keeps temperature records for, and the way from a `Site` to its record series.
///
/// Not every site has one: remote communities and some small towns are missing, so `station(for:)` can return nil.
public struct ClimateRecordStations: Sendable {
    public let stations: [ClimateRecordStation]

    /// Stations by province and normalized name, in English and in French.
    private let index: [String: ClimateRecordStation]

    /// Reads `Endpoint.climateRecordStations`. Each station is listed once per observing station and element in the
    /// file; it appears once here.
    public init(csv data: Data) {
        var seen = Set<String>()
        var stations: [ClimateRecordStation] = []

        for row in CSVTable(data: data).rows {
            guard let id = row["VIRTUAL_CLIMATE_ID"],
                  let nameEn = row["VIRTUAL_STATION_NAME_E"],
                  let province = row["PROVINCE_CODE"].flatMap(Province.forCode),
                  seen.insert(id).inserted
            else { continue }

            stations.append(ClimateRecordStation(
                virtualClimateID: id,
                province: province,
                cityCode: row["WXO_CITY_CODE"] ?? "",
                nameEn: nameEn,
                nameFr: row["VIRTUAL_STATION_NAME_F"] ?? nameEn
            ))
        }

        var index: [String: ClimateRecordStation] = [:]
        for station in stations {
            for name in [station.nameEn, station.nameFr] {
                let key = Self.key(province: station.province.abbreviation, name: name)

                if index[key] == nil {
                    index[key] = station
                }
            }
        }

        self.stations = stations
        self.index = index
    }

    /// The record series for `site`, matched on province and name ("Winnipeg" is "WINNIPEG AREA"), or nil if EC has none.
    ///
    /// Where a city has two series, EC qualifies them and the plain name belongs to the airport's: "Halifax"
    /// is "HALIFAX (AIRPORT) AREA", and "Halifax (Shearwater)" is "HALIFAX (SHEARWATER) AREA".
    public func station(for site: Site) -> ClimateRecordStation? {
        let province = site.provinceCode.uppercased()
        let names = [site.nameEn, site.nameFr]

        return names.lazy.compactMap { index[Self.key(province: province, name: $0)] }.first
            ?? names.lazy.compactMap { index[Self.key(province: province, name: "\($0) Airport")] }.first
    }

    /// "Saint-Rémi" and "SAINT REMI AREA" are the same place: case, accents, punctuation and a trailing "AREA" don't count.
    static func key(province: String, name: String) -> String {
        var words = name
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_CA"))
            .uppercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }

        if words.count > 1, words.last == "AREA" {
            words.removeLast()
        }

        return "\(province)|\(words.joined(separator: " "))"
    }
}
