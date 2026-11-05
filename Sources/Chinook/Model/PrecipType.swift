//
//  PrecipType.swift
//  Chinook
//
//  Created by Gary Kash on 2020-12-18.
//

import Foundation

public struct PrecipType: XMLDecodable {
    public let start: String
    public let end: String

    private enum CodingKeys: String, CodingKey {
        case start
        case end
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        start = container.decodeLenient(String.self, forKey: .start, fallback: "")
        end = container.decodeLenient(String.self, forKey: .end, fallback: "")
    }
}
