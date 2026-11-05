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

    private enum CodingKeys: String, CodingKey {
        case index
        case rank
        case speed
        case gust
        case direction
        case bearing
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        index = try container.decodeIfPresent(Int.self, forKey: .index)
        rank = try container.decodeIfPresent(String.self, forKey: .rank)
        speed = container.decodeLenient(Measurement.self, forKey: .speed, fallback: .empty)
        gust = container.decodeLenient(Measurement.self, forKey: .gust, fallback: .empty)
        direction = try container.decodeIfPresent(Direction.self, forKey: .direction)
        bearing = container.decodeLenient(Measurement.self, forKey: .bearing, fallback: .empty)
    }
}
