//
//  Period.swift
//  Chinook
//
//  Created by Gary Kash on 2020-12-18.
//

import Foundation

public struct Period: XMLDecodable {
    private enum CodingKeys: String, CodingKey {
        case value = ""
        case textForecastName
    }
    
    public let value: String?
    public let textForecastName: String
}
