//
//  Pressure.swift
//  Chinook
//
//  Created by Gary Kash on 2020-12-18.
//

import Foundation

public struct Pressure: XMLDecodable {
    private enum CodingKeys: String, CodingKey {
        case value = ""
        case unitType
        case units
        case change
        case tendency
    }
    
    public let value: Float?
    public let unitType: String
    public let units: String
    public let change: String
    public let tendency: String?
}
