//
//  YesterdayConditions.swift
//  Chinook
//
//  Created by Gary Kash on 2020-12-18.
//

import Foundation

public struct YesterdayConditions: XMLDecodable {
    public let temperature: [Measurement]?
    public let precip: Measurement?
}
