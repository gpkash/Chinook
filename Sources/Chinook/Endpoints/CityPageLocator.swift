//
//  CityPageLocator.swift
//  Chinook
//

import Foundation

enum CityPageError: LocalizedError {
    /// No city page file for the site was found in any directory searched.
    case notPublished(siteCode: String)

    var errorDescription: String? {
        switch self {
        case .notPublished: return "No matching city page file found"
        }
    }
}

/// Finds the newest city page file for a site.
///
/// EC publishes city pages into hourly directories (`/today/citypage_weather/<province>/<UTC hour>/`).
/// The locator owns everything about that layout: the hour arithmetic, reading the directory listing,
/// reusing a listing briefly across sites, and falling back to the previous hour when a site's file
/// hasn't been published into the current one yet. The only seam is how a listing is fetched.
struct CityPageLocator: Sendable {
    typealias ListingFetcher = @Sendable (Endpoint) async throws -> Data

    static let shared = CityPageLocator()

    private let now: @Sendable () -> Date
    private let fetchListing: ListingFetcher
    private let listingLifetime: TimeInterval
    private let listings = ListingStore()

    init(
        now: @escaping @Sendable () -> Date = { Date() },
        listingLifetime: TimeInterval = 60,
        fetchListing: @escaping ListingFetcher = { try await DataLoader.request($0, strategy: .networkOnly).data }
    ) {
        self.now = now
        self.listingLifetime = listingLifetime
        self.fetchListing = fetchListing
    }

    func latestEndpoint(for site: Site, language: Language) async throws -> Endpoint {
        var firstError: Error?

        for directory in searchDirectories(forProvince: site.provinceCode) {
            do {
                let data = try await listings.listing(for: directory, now: now(), lifetime: listingLifetime, fetch: fetchListing)
                let html = String(decoding: data, as: UTF8.self)

                if let filename = Self.latestFilename(in: html, siteCode: site.code, language: language) {
                    return Endpoint(host: .datamart, path: directory.path + filename)
                }
            }
            catch {
                // A directory that doesn't exist yet (top of the hour) just means "look further back".
                firstError = firstError ?? error
            }
        }

        throw firstError ?? CityPageError.notPublished(siteCode: site.code)
    }

    /// The newest file for `siteCode` in a directory listing, or `nil` if the site isn't listed.
    static func latestFilename(in html: String, siteCode: String, language: Language) -> String? {
        let languageComponent = language == .french ? "fr" : "en"
        let pattern = #"href="([^"]*CitypageWeather_"# + NSRegularExpression.escapedPattern(for: siteCode) + "_" + languageComponent + #"\.xml)""#

        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }

        return regex.matches(in: html, range: NSRange(html.startIndex..., in: html))
            .compactMap { match in Range(match.range(at: 1), in: html).map { String(html[$0]) } }
            .max()
    }

    /// The current UTC hour's directory, then the previous hour's (except at hour 0, when it belongs to yesterday).
    private func searchDirectories(forProvince provinceCode: String) -> [Endpoint] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let hour = calendar.component(.hour, from: now())
        let hours = hour > 0 ? [hour, hour - 1] : [hour]

        return hours.map { hour in
            let path = "/today/citypage_weather/\(provinceCode.uppercased())/\(String(format: "%02d", hour))/"
            return Endpoint(host: .datamart, path: path)
        }
    }
}

/// Holds directory listings for a short time and lets simultaneous callers share one fetch.
private actor ListingStore {
    private struct Entry {
        let data: Data
        let fetchedAt: Date
    }

    private var entries: [String: Entry] = [:]
    private var inFlight: [String: Task<Data, Error>] = [:]

    func listing(
        for endpoint: Endpoint,
        now: Date,
        lifetime: TimeInterval,
        fetch: @escaping CityPageLocator.ListingFetcher
    ) async throws -> Data {
        let key = endpoint.path

        if let entry = entries[key], now.timeIntervalSince(entry.fetchedAt) < lifetime {
            return entry.data
        }

        if let task = inFlight[key] {
            return try await task.value
        }

        let task = Task { try await fetch(endpoint) }
        inFlight[key] = task

        do {
            let data = try await task.value
            entries[key] = Entry(data: data, fetchedAt: now)
            inFlight[key] = nil
            return data
        }
        catch {
            inFlight[key] = nil
            throw error
        }
    }
}
