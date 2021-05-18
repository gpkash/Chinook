//
//  Alert.swift
//  Chinook
//
//  Created by Gary Kash on 2020-12-19.
//

import Foundation

public struct Alert: XMLDecodable, Hashable {
    public let identifier: String
    public let sent: String
    public let status: String
    public let msgType: String
    public let source: String
    public let scope: String
    public let code: [String]
    public let note: String
    public let references: String?
    public let info: [AlertInfo]
}

extension Alert: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}
