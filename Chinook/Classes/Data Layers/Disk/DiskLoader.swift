//
//  DiskLoader.swift
//  Chinook
//
//  Created by Gary Kash on 2020-02-22.
//

import Foundation

/// Describes an error when loading assets from disk.
///
/// - missingAsset: The asset is not found on disk.
enum DiskLoaderError: Error {
    case missingAsset
}

/// Handles disk requests.
class DiskLoader: NSObject {
    // MARK: Private Properties

    private let fileManager = FileManager.default
}

extension DiskLoader: DataLoading {
    func request(_ endpoint: Endpoint, completion: @escaping (Result<DataResponse, Error>) -> Void) -> Progress {
        let progress = Progress(totalUnitCount: 1)
        
        do {
            let data = try Data(contentsOf: endpoint.storageURL)
            let dataResponse = DataResponse(data: data, source: .disk)
            progress.completedUnitCount = 1
            completion(.success(dataResponse))

        }
        catch {
            progress.completedUnitCount = 1
            completion(.failure(DiskLoaderError.missingAsset))
        }
        
        return progress
    }
    
    func cancel() {
        
    }
}
