//
//  DiskLoaderState.swift
//  Chinook
//
//  Created by Gary Kash on 2025-10-18.
//

import Foundation

actor DiskLoaderState {
    private var currentTask: Task<DataResponse, Error>?
    
    func set(_ task: Task<DataResponse, Error>?) {
        currentTask = task
    }
    
    func cancel() {
        currentTask?.cancel()
        currentTask = nil
    }
}
