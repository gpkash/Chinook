//
//  Warnings.swift
//  Chinook
//
//  Created by Gary Kash on 2020-12-18.
//

import Foundation

public struct Warnings: XMLDecodable {
    public let url: String?
    public let event: [Event]
}
