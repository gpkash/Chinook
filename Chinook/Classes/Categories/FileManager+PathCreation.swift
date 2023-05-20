//
//  FileManager+PathCreation.swift
//  Chinook
//
//  Created by Gary Kash on 2020-02-26.
//

import Foundation

extension FileManager {
    func createPathIfNeeded(_ path: String) throws {
        do {
            let documentDirectoryPath = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false).absoluteString
            let lastComponentIsAFile = path.last != "/"

            // Isolate the part we need to create by removing the documentDirectory portion.
            let isolatedPath = path.replacingOccurrences(of: documentDirectoryPath, with: "")
            
            // Break into directory names.
            var pathComponents = isolatedPath.components(separatedBy: "/")
            
            // Ignore the last path component if it's a file.
            if lastComponentIsAFile { pathComponents.removeLast() }
            
            var workingPath = URL(fileURLWithPath: documentDirectoryPath)
            
            // Now, iterate and create each directory one at a time.
            for pathComponent in pathComponents {
                workingPath.appendPathComponent(pathComponent)
                if !FileManager.default.directoryExists(at: workingPath) {
                    try FileManager.default.createDirectory(at: workingPath, withIntermediateDirectories: false, attributes: nil)
                }
            }
        }
        catch {
            throw(error)
        }
    }
    
    func directoryExists(at url: URL) -> Bool {
        var isDir : ObjCBool = false
        if fileExists(atPath: url.path, isDirectory:&isDir) {
            return isDir.boolValue
        }
        return false
    }
}
