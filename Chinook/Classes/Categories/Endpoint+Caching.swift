//
//  Endpoint+Caching.swift
//  Chinook
//
//  Created by Gary Kash on 2020-02-26.
//

import Foundation

extension Endpoint {
    public var storageURL: URL {
        let documentDirectory = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)

        // Remove the leading slash from the endpoint path.
        var appendablePath = path.copy() as! String
        appendablePath.remove(at: appendablePath.startIndex)
        
        let fileURL = documentDirectory.appendingPathComponent(appendablePath)

        return fileURL
    }
    
    public func cache(_ data: Data) {
        do {
            try FileManager.default.createPathIfNeeded(storageURL.absoluteString)
            try data.write(to: storageURL, options: .atomicWrite)
        }
        catch {
            print(error.localizedDescription)
        }
    }
}
