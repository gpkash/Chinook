//
//  DailyObservations.swift
//  Chinook
//
//  Created by Gary Kash on 2026-11-06.
//

import Foundation

/// What one station observed on one day. A value is nil when the station didn't report it that day.
public struct DailyObservation: Hashable, Sendable {
    public let year: Int
    public let month: Int
    public let day: Int
    /// The day's highest temperature, in °C.
    public let maxTemperature: Double?
    /// The day's lowest temperature, in °C.
    public let minTemperature: Double?
    /// Snow that fell, in cm. Automated stations don't measure it, so many never have a value.
    public let snowfall: Double?

    public init(year: Int, month: Int, day: Int, maxTemperature: Double? = nil, minTemperature: Double? = nil, snowfall: Double? = nil) {
        self.year = year
        self.month = month
        self.day = day
        self.maxTemperature = maxTemperature
        self.minTemperature = minTemperature
        self.snowfall = snowfall
    }
}

/// One station's observations for a calendar year, as far as the file goes.
public struct DailyObservations: Sendable {
    /// One entry per day in the file, including days that are still to come (they hold no values).
    public let days: [DailyObservation]

    public init(days: [DailyObservation]) {
        self.days = days
    }

    /// Reads a file from `Endpoint.climateDaily(province:climateID:year:)`. Rows that aren't a calendar day are skipped.
    public init(csv data: Data) {
        self.init(days: CSVTable(data: data).rows.compactMap(DailyObservation.init(row:)))
    }

    public func days(inMonth month: Int) -> [DailyObservation] {
        days.filter { $0.month == month }
    }
}

extension DailyObservation {
    fileprivate init?(row: CSVTable.Row) {
        guard let year = row["Year"].flatMap({ Int($0) }),
              let month = row["Month"].flatMap({ Int($0) }),
              let day = row["Day"].flatMap({ Int($0) })
        else { return nil }

        self.init(
            year: year,
            month: month,
            day: day,
            maxTemperature: row["Max Temp (°C)"].flatMap { Double($0) },
            minTemperature: row["Min Temp (°C)"].flatMap { Double($0) },
            snowfall: row["Total Snow (cm)"].flatMap { Double($0) }
        )
    }
}
