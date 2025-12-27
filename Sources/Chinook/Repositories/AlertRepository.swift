//
//  AlertRepository.swift
//  Chinook
//
//  Created by Gary Kash on 2025-10-18.
//  Copyright © 2025 Gary Kash. All rights reserved.
//

import Foundation

public enum AlertRepository {
    public enum Notifications {
        public static let advisoriesUpdated = Notification.Name(rawValue: "com.thefloorislava.retroweather.WeatherRepository.advisoriesUpdated")
    }

    /// Fetch the list of active CAP file URLs for a given station/day/hour.
    /// - Parameters:
    ///   - stationCode: EC station code.
    ///   - day: Day component in the path.
    ///   - hour: Hour component in the path.
    ///   - strategy: Loading strategy (disk/network behavior).
    /// - Returns: The list of `.cap` file URLs discovered in the directory listing.
    public static func fetchManifest(
        forStationCode stationCode: String,
        day: String,
        hour: String,
        strategy: DataLoaderStrategy
    ) async throws -> [URL] {
        try Task.checkCancellation()
        
        let endpoint = Endpoint.alertsManifest(stationCode: stationCode, day: day, hour: hour)
        let response = try await DataLoader.request(endpoint, strategy: strategy)
        
        try Task.checkCancellation()
        
        guard let html = String(data: response.data, encoding: .utf8) else {
            return []
        }
        
        // Extract href attribute values and filter to .cap files.
        let regex = try NSRegularExpression(pattern: #"<a\s+href="([^"]+)">"#)
        let fullRange = NSRange(html.startIndex..<html.endIndex, in: html)
        let matches = regex.matches(in: html, options: [], range: fullRange)
        
        var urls: [URL] = []
        urls.reserveCapacity(matches.count)
        
        let base = "\(endpoint.host.scheme)://\(endpoint.host.hostname)\(endpoint.path)/"
        
        for match in matches {
            guard let range = Range(match.range(at: 1), in: html) else { continue }
            let raw = String(html[range])
            guard raw.hasSuffix(".cap") else { continue }
            
            if let url = URL(string: base + raw) {
                urls.append(url)
            }
        }
        
        return urls
    }
    
    /// Fetches all manifest URLs for every station for yesterday (all 24 hours)
    /// and for today (00:00 up to the current hour), in UTC.
    ///
    /// Errors for individual fetches are ignored; successful URLs are aggregated.
    /// - Parameters:
    ///   - strategy: The loading strategy to use for each request.
    /// - Returns: A flattened array of all discovered CAP file URLs.
    public static func fetchManifests(strategy: DataLoaderStrategy) async throws -> [URL] {
        // Precompute the date strings and hour lists in UTC to match previous behavior.
        let tz = TimeZone(secondsFromGMT: 0) ?? TimeZone(abbreviation: "GMT") ?? TimeZone.current
        
        let dayFormatter = DateFormatter()
        dayFormatter.timeZone = tz
        dayFormatter.dateFormat = "yyyyMMdd"
        
        let hourFormatter = DateFormatter()
        hourFormatter.timeZone = tz
        hourFormatter.dateFormat = "HH"
        
        let now = Date()
        let today = dayFormatter.string(from: now)
        let yesterday = dayFormatter.string(from: now.addingTimeInterval(-24 * 60 * 60))
        
        let currentHour = Int(hourFormatter.string(from: now)) ?? 0
        let todayHours = (0...currentHour).map { String(format: "%02d", $0) }
        let yesterdayHours = (0...23).map { String(format: "%02d", $0) }
        
        // Build the full set of (station, day, hour) work items.
        var work: [(station: StationCode, day: String, hour: String)] = []
        work.reserveCapacity(StationCode.allCases.count * (yesterdayHours.count + todayHours.count))
        for station in StationCode.allCases {
            for h in yesterdayHours { work.append((station, yesterday, h)) }
            for h in todayHours { work.append((station, today, h)) }
        }
        
        var allURLs: [URL] = []
        
        // Support cooperative cancellation before launching tasks
        try Task.checkCancellation()
        
        await withTaskGroup(of: [URL].self) { taskGroup in
            for item in work {
                taskGroup.addTask { @Sendable in
                    // Each child ignores its own errors to mirror old behavior.
                    // For diskWithNetworkFallback, retry with networkOnly if disk data fails.
                    do {
                        return try await AlertRepository.fetchManifest(
                            forStationCode: item.station.rawValue,
                            day: item.day,
                            hour: item.hour,
                            strategy: strategy
                        )
                    } catch {
                        if strategy == .diskWithNetworkFallback {
                            do {
                                return try await AlertRepository.fetchManifest(
                                    forStationCode: item.station.rawValue,
                                    day: item.day,
                                    hour: item.hour,
                                    strategy: .networkOnly
                                )
                            } catch {
                                return []
                            }
                        }
                        
                        return []
                    }
                }
            }
            
            for await urls in taskGroup {
                if !urls.isEmpty { allURLs.append(contentsOf: urls) }
            }
        }
        
        return allURLs
    }
    
    /// Fetch a single `Alert` from the given CAP URL.
    /// - Parameters:
    ///   - url: CAP feed URL for the alert.
    ///   - strategy: Loading strategy (disk/network behavior).
    /// - Returns: A decoded `Alert`.
    public static func fetchAlert(from url: URL, strategy: DataLoaderStrategy) async throws -> Alert {
        try Task.checkCancellation()

        let endpoint = Endpoint.alert(url: url)
        let response = try await DataLoader.request(endpoint, strategy: strategy)

        try Task.checkCancellation()
        return try Alert.decode(fromXML: response.data)
    }
    
    /// Fetch advisories by downloading and decoding multiple `Alert` XML feeds,
    /// then grouping them by designation code.
    /// - Parameters:
    ///   - urls: The list of alert feed URLs to fetch.
    ///   - language: Preferred language when deriving Advisory content.
    ///   - strategy: The `DataLoaderStrategy` to use for each request.
    /// - Returns: Aggregated `Advisory` values. Individual URL failures are ignored.
    public static func fetchAdvisories(
        fromUrls urls: [URL],
        language: Language,
        strategy: DataLoaderStrategy
    ) async throws -> [Advisory] {
        guard !urls.isEmpty else { return [] }

        // Support cooperative cancellation before launching tasks
        try Task.checkCancellation()

        // Fetch and decode all alerts in parallel, ignoring individual failures.
        let alerts: [Alert] = try await withThrowingTaskGroup(of: Alert?.self) { group in
            for url in urls {
                group.addTask { @Sendable in
                    try Task.checkCancellation()
                    let endpoint = Endpoint.alert(url: url)
                    do {
                        let response = try await DataLoader.request(endpoint, strategy: strategy)
                        return try Alert.decode(fromXML: response.data)
                    } catch {
                        // For diskWithNetworkFallback, retry with networkOnly if disk data fails.
                        if strategy == .diskWithNetworkFallback {
                            do {
                                let response = try await DataLoader.request(endpoint, strategy: .networkOnly)
                                return try Alert.decode(fromXML: response.data)
                            } catch {
                                return nil
                            }
                        }
                        return nil
                    }
                }
            }

            var collected: [Alert] = []
            collected.reserveCapacity(urls.count)
            for try await maybeAlert in group {
                if let alert = maybeAlert { collected.append(alert) }
            }
            return collected
        }

        // Build advisories from the decoded alerts (inlined).
        let allAlertInfos = alerts.alertInfos(forLanguage: language)
        let designationCodes: Set = Set(allAlertInfos.compactMap { $0.designationCode })

        var advisories: [Advisory] = []
        advisories.reserveCapacity(designationCodes.count)

        for designationCode in designationCodes {
            let alertInfos = allAlertInfos.filter { $0.designationCode == designationCode }
            advisories.append(Advisory(designationCode: designationCode, alertInfos: alertInfos))
        }
        
        return advisories
    }
    
    @discardableResult
    public static func fetchAdvisories() async throws -> [Advisory] {
        let manifests = try await AlertRepository.fetchManifests(strategy: .diskWithNetworkFallback)
        
        let advisories = try await AlertRepository.fetchAdvisories(
            fromUrls: manifests,
            language: NSLocale.language,
            strategy: .diskWithNetworkFallback
        )

        NotificationCenter.default.post(name: Notifications.advisoriesUpdated, object: advisories)
        
        return advisories
    }
}

// MARK: - Sendable conformances for task-group captures
extension DataLoaderStrategy: @unchecked Sendable {}
extension StationCode: @unchecked Sendable {}
extension Alert: @unchecked Sendable {}
