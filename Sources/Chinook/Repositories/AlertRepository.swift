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
        public static let advisoriesUpdated = Notification.Name(rawValue: "com.thefloorislava.retroweather.AlertRepository.advisoriesUpdated")
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
        try await fetchManifest(forStationCode: stationCode, day: day, hour: hour, strategy: strategy, loader: .shared)
    }

    /// Fetches all manifest URLs for every station for yesterday (all 24 hours)
    /// and for today (00:00 up to the current hour), in UTC.
    ///
    /// Directories for hours that are over never change, so with `.diskWithNetworkFallback` they are read from
    /// disk once cached; the current and previous hours are always refreshed, because they can still gain files.
    ///
    /// Errors for individual fetches are ignored; successful URLs are aggregated.
    /// - Parameters:
    ///   - strategy: The loading strategy to use for each request.
    /// - Returns: A flattened array of all discovered CAP file URLs.
    public static func fetchManifests(strategy: DataLoaderStrategy) async throws -> [URL] {
        try await fetchManifests(strategy: strategy, now: Date(), loader: .shared)
    }

    /// Fetch a single `Alert` from the given CAP URL.
    /// - Parameters:
    ///   - url: CAP feed URL for the alert.
    ///   - strategy: Loading strategy (disk/network behavior).
    /// - Returns: A decoded `Alert`.
    public static func fetchAlert(from url: URL, strategy: DataLoaderStrategy) async throws -> Alert {
        try await fetchAlert(from: url, strategy: strategy, loader: .shared)
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
        try await fetchAdvisories(fromUrls: urls, language: language, strategy: strategy, now: Date(), loader: .shared)
    }

    /// Fetches every current alert and posts the resulting advisories on `Notifications.advisoriesUpdated`.
    @discardableResult
    public static func fetchAdvisories() async throws -> [Advisory] {
        try await fetchAdvisories(now: Date(), loader: .shared)
    }
}

// MARK: - Implementation (loader and clock injectable)

extension AlertRepository {
    static func fetchManifest(
        forStationCode stationCode: String,
        day: String,
        hour: String,
        strategy: DataLoaderStrategy,
        loader: DataLoader
    ) async throws -> [URL] {
        try Task.checkCancellation()

        let endpoint = Endpoint.alertsManifest(stationCode: stationCode, day: day, hour: hour)
        let response = try await loader.request(endpoint, strategy: strategy)

        try Task.checkCancellation()

        guard let html = String(data: response.data, encoding: .utf8) else {
            return []
        }

        // Extract href attribute values and filter to .cap files.
        let regex = try NSRegularExpression(pattern: #"<a\s+href="([^"]+)">"#)
        let matches = regex.matches(in: html, options: [], range: NSRange(html.startIndex..<html.endIndex, in: html))

        let base = "\(endpoint.host.scheme)://\(endpoint.host.hostname)\(endpoint.path)/"

        return matches.compactMap { match in
            guard let range = Range(match.range(at: 1), in: html) else { return nil }

            let raw = String(html[range])
            guard raw.hasSuffix(".cap") else { return nil }

            return URL(string: base + raw)
        }
    }

    static func fetchManifests(strategy: DataLoaderStrategy, now: Date, loader: DataLoader) async throws -> [URL] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current

        let dayFormatter = DateFormatter()
        dayFormatter.calendar = calendar
        dayFormatter.timeZone = calendar.timeZone
        dayFormatter.dateFormat = "yyyyMMdd"

        let today = dayFormatter.string(from: now)
        let yesterday = dayFormatter.string(from: now.addingTimeInterval(-24 * 60 * 60))
        let currentHour = calendar.component(.hour, from: now)

        // Every (station, day, hour) to list, each with the strategy that suits its age.
        var work: [(station: StationCode, day: String, hour: Int, strategy: DataLoaderStrategy)] = []

        for station in StationCode.allCases {
            for hour in 0...23 {
                let isRecent = currentHour == 0 && hour == 23
                work.append((station, yesterday, hour, isRecent ? recent(strategy) : strategy))
            }
            for hour in 0...currentHour {
                let isRecent = hour >= currentHour - 1
                work.append((station, today, hour, isRecent ? recent(strategy) : strategy))
            }
        }

        try Task.checkCancellation()

        let urls = await withTaskGroup(of: [URL].self) { taskGroup in
            for item in work {
                taskGroup.addTask {
                    // A directory that can't be listed just contributes nothing.
                    (try? await fetchManifest(
                        forStationCode: item.station.rawValue,
                        day: item.day,
                        hour: String(format: "%02d", item.hour),
                        strategy: item.strategy,
                        loader: loader
                    )) ?? []
                }
            }

            var collected: [URL] = []
            for await urls in taskGroup {
                collected.append(contentsOf: urls)
            }
            return collected
        }

        return urls.sorted { $0.absoluteString < $1.absoluteString }
    }

    static func fetchAlert(from url: URL, strategy: DataLoaderStrategy, loader: DataLoader) async throws -> Alert {
        try Task.checkCancellation()

        let response = try await loader.request(Endpoint.alert(url: url), strategy: strategy)

        try Task.checkCancellation()

        return try Alert.decode(fromXML: response.data)
    }

    static func fetchAdvisories(
        fromUrls urls: [URL],
        language: Language,
        strategy: DataLoaderStrategy,
        now: Date,
        loader: DataLoader
    ) async throws -> [Advisory] {
        guard !urls.isEmpty else { return [] }

        try Task.checkCancellation()

        // Fetch and decode all alerts in parallel (the loader caps the real concurrency), ignoring individual failures.
        let alerts = await withTaskGroup(of: Alert?.self) { group in
            for url in urls {
                group.addTask {
                    try? await fetchAlert(from: url, strategy: strategy, loader: loader)
                }
            }

            var collected: [Alert] = []
            for await alert in group {
                if let alert { collected.append(alert) }
            }
            return collected
        }

        try Task.checkCancellation()

        return Advisory.advisories(from: alerts, language: language, now: now)
    }

    static func fetchAdvisories(now: Date, loader: DataLoader) async throws -> [Advisory] {
        let manifests = try await fetchManifests(strategy: .diskWithNetworkFallback, now: now, loader: loader)

        let advisories = try await fetchAdvisories(
            fromUrls: manifests,
            language: NSLocale.language,
            strategy: .diskWithNetworkFallback,
            now: now,
            loader: loader
        )

        NotificationCenter.default.post(name: Notifications.advisoriesUpdated, object: advisories)

        return advisories
    }

    /// Hours that may still gain files are never served from disk.
    private static func recent(_ strategy: DataLoaderStrategy) -> DataLoaderStrategy {
        strategy == .diskWithNetworkFallback ? .networkOnly : strategy
    }
}
