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

    private enum CodingKeys: String, CodingKey {
        case dateTime
        case location
        case warnings
        case currentConditions
        case forecastGroup
        case yesterdayConditions
        case riseSet
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dateTime = try container.decode([DateTime].self, forKey: .dateTime)
        location = try container.decode(Location.self, forKey: .location)
        warnings = try container.decodeIfPresent(Warnings.self, forKey: .warnings)
        // When a station isn't reporting, EC publishes an empty `<currentConditions/>`. Treat that as "no
        // observation" rather than failing the whole site, so forecasts still load.
        currentConditions = try? container.decodeIfPresent(CurrentConditions.self, forKey: .currentConditions)
        forecastGroup = try container.decodeIfPresent(ForecastGroup.self, forKey: .forecastGroup)
        yesterdayConditions = try container.decodeIfPresent(YesterdayConditions.self, forKey: .yesterdayConditions)
        riseSet = try container.decodeIfPresent(RiseSet.self, forKey: .riseSet)
    }
}
