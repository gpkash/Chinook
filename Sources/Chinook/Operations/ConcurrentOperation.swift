//
//  ConcurrentOperation.swift
//  Chinook
//
//  Created by Gary Kash on 2020-02-09.
//  Copyright © 2020 Gary Kash. All rights reserved.
//

// Adapted from: https://williamboles.me/building-a-networking-layer-with-operations/

import Foundation

open class ConcurrentOperation<T>: Operation, ProgressReporting, @unchecked Sendable {
    // MARK: Public Properties
    public typealias OperationCompletionHandler<U> = (_ result: Result<U, Error>) -> Void

    public var completionHandler: (OperationCompletionHandler<T>)?

    public enum State: String {
        case ready = "isReady"
        case executing = "isExecuting"
        case finished = "isFinished"
    }
    
    public var state = State.ready {
        willSet {
            willChangeValue(forKey: newValue.rawValue)
            willChangeValue(forKey: state.rawValue)
        }
        didSet {
            didChangeValue(forKey: oldValue.rawValue)
            didChangeValue(forKey: state.rawValue)
        }
    }
    
    public var progress = Progress(totalUnitCount: 1)
    
    
    // MARK: Property Overrides

    override public var isReady: Bool {
        return super.isReady && state == .ready
    }

    override public var isExecuting: Bool {
        return state == .executing
    }

    override public var isFinished: Bool {
        return state == .finished
    }
    
    
    // MARK: - Lifecycle
    
    // MARK: - Function Overrides
    
    override open func start() {
        guard !isCancelled else {
            finish()
            return
        }

        if !isExecuting {
            state = .executing
        }

        main()
    }
    
    override open func cancel() {
        super.cancel()

        finish()
    }
    
    
    // MARK: - Public Functions
        
    open func finish() {
        if isExecuting {
            state = .finished
        }
        
        progress.completedUnitCount = progress.totalUnitCount
    }
    
    open func complete(result: Result<T, Error>) {
        finish()

        if !isCancelled {
            completionHandler?(result)
        }
    }
}
