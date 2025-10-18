//
//  Precipitation.swift
//  Chinook
//
//  Created by Gary Kash on 2020-12-18.
//

import Foundation

public struct Precipitation: XMLDecodable {
    public let textSummary: String?
    public let precipType: PrecipType
}
