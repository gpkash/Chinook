//
//  Measurement.swift
//  Chinook
//
//  Created by Gary Kash on 2020-12-18.
//

import Foundation

public struct Measurement: XMLDecodable {
    public let value: String?
    public let index: String?
    public let unitType: String?
    public let units: String?
    public let `class`: String?
    public let category: String?
    public let period: String?
    public let year: String?
}
