//
//  HourlyForecastGroup.swift
//  Chinook
//
//  Created by Gary Kash on 2020-12-18.
//

import Foundation

public struct HourlyForecastGroup: XMLDecodable {
    public let dateTime: [DateTime]
    public let hourlyForecast: [HourlyForecast]
}
