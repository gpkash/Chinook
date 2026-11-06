//
//  MonthlyClimateSummary.swift
//  Chinook
//
//  Created by Gary Kash on 2026-11-06.
//

import Foundation

/// A temperature, in °C, and the day of the month it happened on.
public struct DayTemperature: Hashable, Sendable {
    public let temperature: Double
    public let day: Int

    public init(temperature: Double, day: Int) {
        self.temperature = temperature
        self.day = day
    }
}

/// How one calendar month turned out at a site's station, next to how that month usually goes.
public struct MonthlyClimateSummary: Hashable, Sendable {
    /// The station that observed the month.
    public let station: ClimateStation
    public let year: Int
    public let month: Int
    /// How many of the month's days have a temperature. Fewer than the month holds when the station missed some or the month isn't over.
    public let daysObserved: Int
    /// The average of the days' highs, in °C. Nil when no day has one.
    public let averageHigh: Double?
    /// The average of the days' lows, in °C. Nil when no day has one.
    public let averageLow: Double?
    /// The month's snowfall in cm. Nil when the station doesn't measure snow.
    public let snowfall: Double?
    /// The month's hottest high, and the day it was on.
    public let warmest: DayTemperature?
    /// The month's coldest low, and the day it was on.
    public let coldest: DayTemperature?
    /// The 1981–2010 normals for the month, if EC publishes them for a station near the site.
    public let normals: MonthlyNormals?

    public init(
        station: ClimateStation,
        year: Int,
        month: Int,
        daysObserved: Int,
        averageHigh: Double?,
        averageLow: Double?,
        snowfall: Double?,
        warmest: DayTemperature?,
        coldest: DayTemperature?,
        normals: MonthlyNormals?
    ) {
        self.station = station
        self.year = year
        self.month = month
        self.daysObserved = daysObserved
        self.averageHigh = averageHigh
        self.averageLow = averageLow
        self.snowfall = snowfall
        self.warmest = warmest
        self.coldest = coldest
        self.normals = normals
    }
}

extension MonthlyClimateSummary {
    /// The share of a month's days snowfall must have been reported on before the total is believed.
    /// A station that reports snow on only some days would otherwise understate it.
    static let minimumSnowfallCoverage = 0.8

    /// Summarises `month` of `year` from a station's daily observations.
    init(station: ClimateStation, year: Int, month: Int, observations: DailyObservations, normals: MonthlyNormals?, calendar: Calendar = Calendar(identifier: .gregorian)) {
        let days = observations.days(inMonth: month).filter { $0.year == year }
        let highs = days.compactMap { day in day.maxTemperature.map { DayTemperature(temperature: $0, day: day.day) } }
        let lows = days.compactMap { day in day.minTemperature.map { DayTemperature(temperature: $0, day: day.day) } }
        let snowfalls = days.compactMap(\.snowfall)

        let daysInMonth = calendar.range(of: .day, in: .month, for: calendar.date(from: DateComponents(year: year, month: month)) ?? Date())?.count ?? 31
        let hasSnowfall = !snowfalls.isEmpty && Double(snowfalls.count) >= Double(daysInMonth) * Self.minimumSnowfallCoverage

        self.init(
            station: station,
            year: year,
            month: month,
            daysObserved: Set(highs.map(\.day)).union(lows.map(\.day)).count,
            averageHigh: highs.isEmpty ? nil : highs.map(\.temperature).reduce(0, +) / Double(highs.count),
            averageLow: lows.isEmpty ? nil : lows.map(\.temperature).reduce(0, +) / Double(lows.count),
            snowfall: hasSnowfall ? snowfalls.reduce(0, +) : nil,
            warmest: highs.max { $0.temperature < $1.temperature },
            coldest: lows.min { $0.temperature < $1.temperature },
            normals: normals
        )
    }
}
