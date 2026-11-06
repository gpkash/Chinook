//
//  ClimateNormals.swift
//  Chinook
//
//  Created by Gary Kash on 2026-11-06.
//

import Foundation

/// What a month is usually like at a station: the average over 1981–2010.
public struct MonthlyNormals: Hashable, Sendable {
    public let month: Int
    /// The average of the month's daily highs, in °C.
    public let averageHigh: Double?
    /// The average of the month's daily lows, in °C.
    public let averageLow: Double?
    /// The month's usual snowfall, in cm.
    public let snowfall: Double?

    public init(month: Int, averageHigh: Double? = nil, averageLow: Double? = nil, snowfall: Double? = nil) {
        self.month = month
        self.averageHigh = averageHigh
        self.averageLow = averageLow
        self.snowfall = snowfall
    }
}

/// One station's 1981–2010 climate normals. EC publishes them by month, not by day.
public struct ClimateNormals: Sendable {
    static let firstYear = 1981
    static let lastYear = 2010

    /// January to December, in order. Empty when the file isn't a normals file.
    public let months: [MonthlyNormals]

    public init(months: [MonthlyNormals]) {
        self.months = months
    }

    /// Reads a file from `Endpoint.climateNormals(province:climateID:)`.
    ///
    /// The file isn't a table: it's a dozen headed sections, with the months across. Only the rows
    /// Chinook uses are read, found by their labels.
    public init(csv data: Data) {
        let records = CSVTable.records(in: data)

        // The months are named once, above the first section.
        guard let header = records.firstIndex(where: { $0.count > 12 && $0[1] == "Jan" && $0[12] == "Dec" }) else {
            self.init(months: [])
            return
        }

        func values(labelled prefix: String) -> [Double?] {
            let row = records[(header + 1)...].first { $0.first?.hasPrefix(prefix) == true }

            return (1...12).map { month in
                guard let row, month < row.count else { return nil }
                return Double(row[month].trimmingCharacters(in: .whitespaces))
            }
        }

        let highs = values(labelled: "Daily Maximum")
        let lows = values(labelled: "Daily Minimum")
        let snow = values(labelled: "Snowfall")

        self.init(months: (1...12).map { month in
            MonthlyNormals(month: month, averageHigh: highs[month - 1], averageLow: lows[month - 1], snowfall: snow[month - 1])
        })
    }

    public func normals(forMonth month: Int) -> MonthlyNormals? {
        months.first { $0.month == month }
    }
}
