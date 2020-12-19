//
//  Almanac.swift
//  Chinook
//
//  Created by Gary Kash on 2020-12-18.
//

import Foundation

public struct Almanac: XMLDecodable {
    public let temperature: [Measurement]
    public let precipitation: [Measurement]
    public let pop: Measurement
}
