//
//  FetchAlertManifestsOperation.swift
//  Chinook
//
//  Created by Gary Kash on 2020-12-19.
//

import Foundation

public class FetchAlertManifestsOperation: ConcurrentOperation<[URL]> {
    
    // MARK: Private Properties

    private let dataLoader: DataLoader
    private let queue = CompletableOperationQueue()
    private var urls: [URL] = []
    
    private let operations: [ConcurrentOperation<URL>] = []
    private let dateFormatter = DateFormatter()

    private lazy var today = dateFormatter.string(for: Date())!
    private var todayHours: [String] {
        let hourDateFormatter = DateFormatter()
        hourDateFormatter.timeZone = TimeZone(secondsFromGMT:0)
        hourDateFormatter.dateFormat = "HH"
        
        guard let currentHourString = hourDateFormatter.string(for: Date()),
              let currentHour = Int(currentHourString) else { return [] }
        
        var hours: [String] = []
        for hour in 0...currentHour { hours.append(String(format: "%02d", hour)) }
        return hours
    }

    private lazy var yesterday = dateFormatter.string(for: Date(timeIntervalSinceNow: -(24*60*60)))!
    private let yesterdayHours = ["00","01","02","03","04","05","06","07","08","09","10","11","12","13","14","15","16","17","18","19","20","21","22","23"]

    // MARK: Property Overrides
    
    // MARK: - Lifecycle
    
    public init(strategy: DataLoaderStrategy) {
        self.dataLoader = DataLoader(strategy: strategy)
        
        super.init()
        
        dateFormatter.timeZone = TimeZone(secondsFromGMT:0)
        dateFormatter.dateFormat = "yyyyMMdd"
        
        queue.maxConcurrentOperationCount = 20
        
        queue.operationQueueFinished = { [weak self] in
            guard let self = self else { return }
            self.complete(result: .success(self.urls))
        }
        
        // set up progress before queuing the operations
        let operationCount = (StationCode.allCases.count * yesterdayHours.count) + (StationCode.allCases.count * todayHours.count)
        progress = Progress(totalUnitCount: Int64(operationCount))
    }
    
    
    // MARK: - Function Overrides
    
    override public func start() {
        super.start()
        
        guard !isCancelled else {
            finish()
            return
        }
        
        // for each station...
        for station in StationCode.allCases {
            // for yesterday...
            for hour in yesterdayHours {
                queue.addOperation(makeManifestFetchOperation(stationCode: station.rawValue, day: yesterday, hour: hour))
            }
            
            // for today...
            for hour in todayHours {
                queue.addOperation(makeManifestFetchOperation(stationCode: station.rawValue, day: today, hour: hour))
            }
        }
    }
    
    override public func cancel() {
        dataLoader.cancel()
        super.cancel()
    }
    
    // MARK: - Private Functions
    
    private func makeManifestFetchOperation(stationCode: String, day: String, hour: String) -> FetchAlertManifestOperation {
        let operation = FetchAlertManifestOperation(stationCode: stationCode, day: day, hour: hour, strategy: dataLoader.strategy)
        operation.completionHandler = { [weak self] result in
            switch result {
            case .success(let response):
                self?.urls.append(contentsOf: response)

            case .failure(_):
                // ignore
                break
            }
        }
        
        progress.addChild(operation.progress, withPendingUnitCount: 1)
        
        return operation
    }
}
