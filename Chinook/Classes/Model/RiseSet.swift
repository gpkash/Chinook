//
//  RiseSet.swift
//  Chinook
//
//  Created by Gary Kash on 2020-12-18.
//

import Foundation

public struct RiseSet: XMLDecodable {
    public let disclaimer: String
    public let dateTime: [DateTime]
}
