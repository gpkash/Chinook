//
//  CurrentConditions.swift
//  Chinook
//
//  Created by Gary Kash on 2020-12-18.
//

import Foundation

public struct CurrentConditions: XMLDecodable {
    public let station: Station
    public let dateTime: [DateTime]
    public let condition: String?
    public let iconCode: IconCode?
    public let temperature: Measurement
    public let dewpoint: Measurement
    public let pressure: Pressure
    public let visibility: Measurement
    public let relativeHumidity: Measurement
    public let windChill: Measurement?
    public let humidex: Measurement?
    public let wind: Wind
}
