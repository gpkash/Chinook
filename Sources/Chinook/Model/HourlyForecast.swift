//
//  HourlyForecast.swift
//  Chinook
//
//  Created by Gary Kash on 2020-12-18.
//

import Foundation

public struct HourlyForecast: XMLDecodable {
    public let dateTimeUTC: String
    public let condition: String
    public let iconCode: IconCode
    public let temperature: Measurement
    public let lop: Measurement
    public let windChill: Measurement
    public let humidex: Measurement
    public let wind: Wind
}
