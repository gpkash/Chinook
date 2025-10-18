//
//  ForecastGroup.swift
//  Chinook
//
//  Created by Gary Kash on 2020-12-18.
//

import Foundation

public struct ForecastGroup: XMLDecodable {
    public let dateTime: [DateTime]?
    public let regionalNormals: RegionalNormals?
    public let forecast: [Forecast]?
}
