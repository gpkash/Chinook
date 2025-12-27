//
//  IconCode.swift
//  Chinook
//
//  Created by Gary Kash on 2020-12-18.
//

import Foundation

public struct IconCode: XMLDecodable {
    private enum CodingKeys: String, CodingKey {
        case value = ""
        case format
    }

    public let value: String?
    public let format: String?
}
