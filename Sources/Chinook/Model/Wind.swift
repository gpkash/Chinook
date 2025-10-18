//
//  Wind.swift
//  Chinook
//
//  Created by Gary Kash on 2020-12-18.
//

import Foundation

public struct Wind: XMLDecodable {
    public let index: Int?
    public let rank: String?
    public let speed: Measurement
    public let gust: Measurement
    public let direction: Direction?
    public let bearing: Measurement
}
