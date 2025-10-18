//
//  DataResponse.swift
//  Chinook
//
//  Created by Gary Kash on 2020-02-23.
//

import Foundation

public enum DataResponseSource {
    case network
    case disk
}

public struct DataResponse: Equatable {
    public let data: Data
    public let source: DataResponseSource
    
    public init(data: Data, source: DataResponseSource) {
        self.data = data
        self.source = source
    }
    
    public static func == (lhs: DataResponse, rhs: DataResponse) -> Bool {
        guard lhs.data == rhs.data else { return false }
        guard lhs.source == rhs.source else { return false }
        
        return true
    }
}
