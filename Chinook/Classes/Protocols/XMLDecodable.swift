//
//  XMLDecodable.swift
//  Chinook
//
//  Created by Gary Kash on 2020-02-02.
//  Copyright © 2020 Gary Kash. All rights reserved.
//

import Foundation
import XMLCoder

protocol XMLDecodable: Codable {
    static func decode(fromXML data: Data) throws -> Self
}

extension XMLDecodable {
    
    /// A convenience function for all objects conforming to `XMLDecodable` that automatically evokes
    /// a `XMLDecoder` to decode the data passed in.
    /// - Parameter data: XML string encoded data.
    /// - throws: `DecodingError.dataCorrupted` if values requested from the payload are corrupted, or if the given data is not valid XML.
    /// - throws: An error if any box throws an error during decoding.
    static func decode(fromXML data: Data) throws -> Self {
        return try XMLDecoder().decode(Self.self, from: data)
    }
}
