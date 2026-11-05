//
//  Measurement.swift
//  Chinook
//
//  Created by Gary Kash on 2020-12-18.
//

import Foundation

public struct Measurement: XMLDecodable {
    private enum CodingKeys: String, CodingKey {
        case value = ""
        case index
        case unitType
        case units
        case `class`
        case category
        case period
        case year
    }

    public let value: String?
    public let index: String?
    public let unitType: String?
    public let units: String?
    public let `class`: String?
    public let category: String?
    public let period: String?
    public let year: String?

    /// A measurement EC left out entirely.
    static var empty: Measurement { Measurement(value: nil, index: nil, unitType: nil, units: nil, class: nil, category: nil, period: nil, year: nil) }
}
