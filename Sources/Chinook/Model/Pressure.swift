//
//  Pressure.swift
//  Chinook
//
//  Created by Gary Kash on 2020-12-18.
//

import Foundation

public struct Pressure: XMLDecodable {
    public let value: Float?
    public let unitType: String
    public let units: String
    public let change: String
    public let tendency: String?
}
