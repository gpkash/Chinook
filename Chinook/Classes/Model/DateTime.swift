//
//  DateTime.swift
//  Chinook
//
//  Created by Gary Kash on 2020-12-18.
//

import Foundation

public struct DateTime: XMLDecodable {
    public let name: String
    public let zone: String
    public let UTCOffset: String
    public let year: Int
    public let month: Int
    public let day: Int
    public let hour: Int
    public let minute: Int
    public let timeStamp: Double
    public let textSummary: String
}
