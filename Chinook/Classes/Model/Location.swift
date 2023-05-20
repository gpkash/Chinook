//
//  Location.swift
//  Chinook
//
//  Created by Gary Kash on 2020-12-18.
//

import Foundation

public struct Location: XMLDecodable {
    public let continent: String
    public let country: String
    public let province: String
    public let name: Name
    public let region: String?
}
