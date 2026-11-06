//
//  TemperatureRecords.swift
//  Chinook
//
//  Created by Gary Kash on 2026-11-05.
//

import Foundation

/// A temperature, in °C, and the year it was set.
public struct TemperatureRecord: Hashable, Sendable {
    public let temperature: Double
    public let year: Int

    public init(temperature: Double, year: Int) {
        self.temperature = temperature
        self.year = year
    }
}

/// The records for one calendar day. A record is nil when EC has none for that day.
public struct DailyTemperatureRecords: Hashable, Sendable {
    public let month: Int
    public let day: Int
    /// The hottest high ever recorded on this day.
    public let recordHigh: TemperatureRecord?
    /// The coldest low ever recorded on this day.
    public let recordLow: TemperatureRecord?
    /// The coldest high: the day that never got warm.
    public let coldestHigh: TemperatureRecord?
    /// The warmest low: the night that never got cold.
    public let warmestLow: TemperatureRecord?

    public init(
        month: Int,
        day: Int,
        recordHigh: TemperatureRecord? = nil,
        recordLow: TemperatureRecord? = nil,
        coldestHigh: TemperatureRecord? = nil,
        warmestLow: TemperatureRecord? = nil
    ) {
        self.month = month
        self.day = day
        self.recordHigh = recordHigh
        self.recordLow = recordLow
        self.coldestHigh = coldestHigh
        self.warmestLow = warmestLow
    }
}

/// A city's temperature records for every day of the year, as they stand today.
public struct TemperatureRecords: Sendable {
    public let station: ClimateRecordStation
    /// One entry for each calendar day EC lists, February 29 included.
    public let days: [DailyTemperatureRecords]

    public init(station: ClimateRecordStation, days: [DailyTemperatureRecords]) {
        self.station = station
        self.days = days
    }

    /// Reads a file from `Endpoint.climateRecords(province:virtualClimateID:)`. Rows that aren't a calendar day are skipped.
    public init(csv data: Data, station: ClimateRecordStation) {
        self.init(station: station, days: CSVTable(data: data).rows.compactMap(DailyTemperatureRecords.init(row:)))
    }

    public func records(month: Int, day: Int) -> DailyTemperatureRecords? {
        days.first { $0.month == month && $0.day == day }
    }

    /// The records for `date`'s calendar day, in `calendar`.
    public func records(on date: Date, calendar: Calendar = .current) -> DailyTemperatureRecords? {
        let components = calendar.dateComponents([.month, .day], from: date)

        guard let month = components.month, let day = components.day else { return nil }

        return records(month: month, day: day)
    }
}

extension DailyTemperatureRecords {
    fileprivate init?(row: CSVTable.Row) {
        guard let month = row["LOCAL_MONTH"].flatMap({ Int($0) }),
              let day = row["LOCAL_DAY"].flatMap({ Int($0) })
        else { return nil }

        self.init(
            month: month,
            day: day,
            recordHigh: TemperatureRecord(row, temperature: "RECORD_HIGH_MAX_TEMP", year: "RECORD_HIGH_MAX_TEMP_YR"),
            recordLow: TemperatureRecord(row, temperature: "RECORD_LOW_MIN_TEMP", year: "RECORD_LOW_MIN_TEMP_YR"),
            coldestHigh: TemperatureRecord(row, temperature: "RECORD_LOW_MAX_TEMP", year: "RECORD_LOW_MAX_TEMP_YR"),
            warmestLow: TemperatureRecord(row, temperature: "RECORD_HIGH_MIN_TEMP", year: "RECORD_HIGH_MIN_TEMP_YR")
        )
    }
}

extension TemperatureRecord {
    fileprivate init?(_ row: CSVTable.Row, temperature: String, year: String) {
        guard let temperature = row[temperature].flatMap({ Double($0) }),
              let year = row[year].flatMap({ Int($0) })
        else { return nil }

        self.init(temperature: temperature, year: year)
    }
}
