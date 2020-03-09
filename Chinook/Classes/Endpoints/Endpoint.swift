//
//  Endpoint.swift
//  Chinook
//
//  Created by Gary Kash on 2020-02-01.
//  Copyright © 2020 Gary Kash. All rights reserved.
//

import Foundation

/// Describes an endpoint for a resource. This may refer to either a disk resource or network resource.
public struct Endpoint {
    /// The host in which this endpoint is on.
    let host: Host
    /// The url path. Should begin with a `/`.
    let path: String
    /// The query parameters for this endpoint.
    let queryItems: [URLQueryItem]?
        
    init(host: Host, path: String, queryItems: [URLQueryItem]? = nil) {
        self.host = host
        self.path = path
        self.queryItems = queryItems
    }
}

// MARK: - Network Extensions

extension Endpoint {
    // We still have to keep 'url' as an optional, since we're
    // dealing with dynamic components that could be invalid.
    var url: URL? {
        var components = URLComponents()
        components.scheme = host.scheme
        components.host = host.hostname
        components.path = path
        components.queryItems = queryItems

        return components.url
    }
}

// MARK: - Disk Extensions

extension Endpoint {
}
