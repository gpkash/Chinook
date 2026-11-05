//
//  AlertaArea.swift
//  Chinook
//
//  Created by Gary Kash on 2020-12-22.
//

import Foundation

public struct AlertArea: XMLDecodable, Hashable, Sendable {
    public let areaDesc: String
    public let polygon: String
    public let geocode: [AlertGeocode]
}
