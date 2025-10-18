//
//  AbbreviatedForecast.swift
//  Chinook
//
//  Created by Gary Kash on 2020-12-18.
//

import Foundation

public struct AbbreviatedForecast: XMLDecodable {
    public let iconCode: IconCode
    public let pop: Measurement
    public let textSummary: String
}
