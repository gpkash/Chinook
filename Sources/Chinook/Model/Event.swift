//
//  Event.swift
//  Chinook
//
//  Created by Gary Kash on 2020-12-18.
//

import Foundation

public struct Event: XMLDecodable {
    public let type: String
    public let priority: String?
    public let alertColourLevel: String?
    public let description: String
    public let dateTime: [DateTime]
}
