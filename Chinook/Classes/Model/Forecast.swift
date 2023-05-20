//
//  Forecast.swift
//  Chinook
//
//  Created by Gary Kash on 2020-12-18.
//

import Foundation

public struct Forecast: XMLDecodable {
    public let period: Period?
    public let textSummary: String?
    public let cloudPrecip: CloudPrecip?
    public let abbreviatedForecast: AbbreviatedForecast?
    public let temperatures: Temperatures?
    public let winds: Winds?
    public let humidex: Measurement? // This needs to be clarified.
    public let precipitation: Precipitation
    public let windChill: WindChill?
    public let relativeHumidity: Measurement?
}
