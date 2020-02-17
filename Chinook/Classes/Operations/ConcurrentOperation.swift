//
//  ConcurrentOperation.swift
//  Chinook
//
//  Created by Gary Kash on 2020-02-09.
//  Copyright © 2020 Gary Kash. All rights reserved.
//

// Adapted from: https://williamboles.me/building-a-networking-layer-with-operations/

import Foundation

public class ConcurrentOperation: Operation {

    // MARK: Public Properties
    
    public typealias OperationCompletionHandler = (_ result: Result<Any, Error>) -> Void

    public var completionHandler: (OperationCompletionHandler)?

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
    
    
    // MARK: - Function Overrides
    
    override public func start() {
        guard !isCancelled else {
            finish()
            return
        }

        if !isExecuting {
            state = .executing
        }

        main()
    }
    
    override public func cancel() {
        super.cancel()

        finish()
    }
    
    
    // MARK: - Public Functions
        
    public func finish() {
        if isExecuting {
            state = .finished
        }
    }
    
    public func complete(result: Result<Any, Error>) {
        finish()

        if !isCancelled {
            completionHandler?(result)
        }
    }
}
