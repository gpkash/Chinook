//
//  SiteData.swift
//  Chinook
//
//  Created by Gary Kash on 2020-02-02.
//  Copyright © 2020 Gary Kash. All rights reserved.
//

import Foundation

public struct SiteData: XMLDecodable {
    public let dateTime: [DateTime]
    public let location: Location
    public let warnings: Warnings?
    public let currentConditions: CurrentConditions?
    public let forecastGroup: ForecastGroup?
    public let yesterdayConditions: YesterdayConditions?
    public let riseSet: RiseSet?
    public let almanac: Almanac?
}
