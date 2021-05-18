//
//  FetchAlertManifestOperation.swift
//  Chinook
//
//  Created by Gary Kash on 2020-12-19.
//

import Foundation

public class FetchAlertManifestOperation: ConcurrentOperation<[URL]> {
    
    // MARK: Private Properties

    private let doubleQuoteCharacterSet = CharacterSet(charactersIn: "\"")

    private let dataLoader: DataLoader
    private let stationCode: String
    private let day: String
    private let hour: String
    
    
    // MARK: Property Overrides
    
    // MARK: - Lifecycle
    
    public init(stationCode: String, day: String, hour: String, strategy: DataLoaderStrategy) {
        self.stationCode = stationCode
        self.day = day
        self.hour = hour
        self.dataLoader = DataLoader(strategy: strategy)
        super.init()
    }
    
    
    // MARK: - Function Overrides
    
    override public func start() {
        super.start()
        
        guard !isCancelled else {
            finish()
            return
        }
        
        let endpoint = Endpoint.alertsManifest(stationCode: stationCode, day: day, hour: hour)
        let dataLoaderProgress = dataLoader.request(endpoint) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let dataResponse):
                    var alertCapFileURLs: [URL] = []
                    
                    // Brutal, but EC doesn't offer up a manifest of active cap files. 🤦‍♂️
                    // So, use regex and extract the .cap urls from the html response
                    // of the parent directory.
                    if let html = String(data: dataResponse.data, encoding: .utf8),
                       let regex = try? NSRegularExpression(pattern: "([\"'])(?:(?=(\\\\?))\\2.)*?\\1") {
                        let fullRange = NSRange(location: 0, length: html.utf8.count)
                        let matches = regex.matches(in: html, options: [], range: fullRange)

                        for match in matches {
                            if let range = Range(match.range) {
                                let urlString = html.substring(with: range).trimmingCharacters(in: self.doubleQuoteCharacterSet)
                                if urlString.hasSuffix(".cap"),
                                   let url = URL(string: "\(endpoint.host.scheme)://\(endpoint.host.hostname)\(endpoint.path)/\(urlString)") {
                                    alertCapFileURLs.append(url)
                                }
                            }
                        }
                    }
                    
                    self.complete(result: .success(alertCapFileURLs))
                    
                    
                case .failure(let error):
                    self.complete(result: .failure(error))
                }
            }
        }

        progress.addChild(dataLoaderProgress, withPendingUnitCount: 1)
    }
    
    override public func cancel() {
        dataLoader.cancel()
        super.cancel()
    }
}
