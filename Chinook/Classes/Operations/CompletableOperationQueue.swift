//
//  CompletableOperationQueue.swift
//  RetroWeather
//
//  Created by Gary Kash on 2020-03-09.
//  Copyright © 2020 Gary Kash. All rights reserved.
//

import Foundation

public class CompletableOperationQueue: OperationQueue {
    
    // MARK: Public Properties
    
    public var operationQueueFinished: (() -> Void)?
    
    
    // MARK: Private Properties
    
    private var operationsObserver: NSKeyValueObservation?

    
    // MARK: - Lifecycle

    override init() {
        super.init()
        
        operationsObserver = observe(\.operations, changeHandler: { [weak self] _, _ in
            guard let self else { return }
            guard self.operations.isEmpty else { return }
            self.operationQueueFinished?()
        })
    }
}
