//
//  AlertParameter.swift
//  Chinook
//
//  Created by Gary Kash on 2020-12-22.
//

import Foundation

public struct AlertParameter: XMLDecodable, Hashable {
    public let valueName: String
    public let value: String
}
