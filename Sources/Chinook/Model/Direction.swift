//
//  Direction.swift
//  Chinook
//
//  Created by Gary Kash on 2020-12-18.
//

import Foundation

public struct Direction: XMLDecodable {
    private enum CodingKeys: String, CodingKey {
        case value = ""
        case windDirFull
    }
    
    public let value: String?
    public let windDirFull: String?
}
