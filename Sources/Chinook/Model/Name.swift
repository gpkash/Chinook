//
//  Name.swift
//  Chinook
//
//  Created by Gary Kash on 2020-12-18.
//

import Foundation

public struct Name: XMLDecodable {
    private enum CodingKeys: String, CodingKey {
        case value = ""
        case lat
        case lon
    }

    public let value: String?
    public let lat: String
    public let lon: String
}
