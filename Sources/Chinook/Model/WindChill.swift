//
//  File.swift
//  Chinook
//
//  Created by Gary Kash on 2020-12-18.
//

import Foundation

public struct WindChill: XMLDecodable {
    public let textSummary: String?
    public let calculated: [Measurement]
}

