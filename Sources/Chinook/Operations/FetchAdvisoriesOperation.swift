//
//  FetchAdvisoriesOperation.swift
//  Chinook
//
//  Created by Gary Kash on 2020-12-21.
//

import Foundation

public class FetchAdvisoriesOperation: ConcurrentOperation<[Advisory]>, @unchecked Sendable {
    
    // MARK: Private Properties

    private let dataLoader: DataLoader
    private let queue = CompletableOperationQueue()
    private var alerts: [Alert] = []
    private let operations: [ConcurrentOperation<Alert>] = []
    private var urlsManifest: [URL]
    private let language: Language


    // MARK: Property Overrides
    
    // MARK: - Lifecycle
    
    public init(urlsManifest: [URL], language: Language, strategy: DataLoaderStrategy) {
        self.urlsManifest = urlsManifest
        self.language = language
        self.dataLoader = DataLoader(strategy: strategy)
        
        super.init()
                
        queue.maxConcurrentOperationCount = 20
        
        queue.operationQueueFinished = { [weak self] in
            guard let self else { return }
            
            let advisories = self.makeAdvisories(self.alerts)
            self.complete(result: .success(advisories))
        }
        
        progress = Progress(totalUnitCount: Int64(urlsManifest.count))
    }
    
    
    // MARK: - Function Overrides
    
    override public func start() {
        super.start()
        
        guard !isCancelled else {
            finish()
            return
        }
        
        for url in urlsManifest {
            let operation = makeFetchAlertOperation(url: url)
            queue.addOperation(operation)
        }
    }
    
    override public func cancel() {
        dataLoader.cancel()
        super.cancel()
    }
    
    // MARK: - Private Functions
    
    private func makeFetchAlertOperation(url: URL) -> FetchAlertOperation {
        let operation = FetchAlertOperation(url: url, strategy: dataLoader.strategy)
        operation.completionHandler = { [weak self] result in
            guard let self else { return }
            self.progress.completedUnitCount = Int64(self.urlsManifest.count - self.queue.operationCount)
            
            switch result {
            case .success(let response):
                self.alerts.append(response)

            case .failure(_):
                // ignore
                break
            }
        }
        
        return operation
    }
    
    private func makeAdvisories(_ allAlerts: [Alert]) -> [Advisory] {
        let allAlertInfos = allAlerts.alertInfos(forLanguage: language)
        let designationCodes: Set = Set(allAlertInfos.compactMap({ $0.designationCode }))

        var advisories: [Advisory] = []
        
        for designationCode in designationCodes {
            // filter the alert infos to only those whose designation codes match.
            let alertInfos = allAlertInfos.filter { $0.designationCode == designationCode }
            advisories.append(Advisory(designationCode: designationCode, alertInfos: alertInfos))
        }

        return advisories
    }
}
