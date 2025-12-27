//
//  NetworkLoaderState.swift
//  Chinook
//
//  Created by Gary Kash on 2025-10-18.
//

import Foundation

actor NetworkLoaderState {
    private var activeTask: URLSessionDataTask?
    
    func set(_ task: URLSessionDataTask?) {
        activeTask = task
    }
    
    func cancel() {
        activeTask?.cancel()
        activeTask = nil
    }
}
