//
//  Station.swift
//  Chinook
//
//  Created by Gary Kash on 2020-12-18.
//

import Foundation

public struct Station: XMLDecodable {
    private enum CodingKeys: String, CodingKey {
        case value = ""
        case code
        case lat
        case lon
    }
    
    public let value: String?
    public let code: String
    public let lat: String
    public let lon: String
}
