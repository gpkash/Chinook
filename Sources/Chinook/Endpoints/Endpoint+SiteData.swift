//
//  Endpoint+SiteData.swift
//  Chinook
//
//  Created by Gary Kash on 2020-02-22.
//

import Foundation

private actor URLDataCache {
    static let shared = URLDataCache()

    private var cache: [URL: Data] = [:]
    private var inFlight: [URL: Task<Data, Error>] = [:]
    private var cacheCleanupTask: Task<Void, Never>?

    private func clearCache() {
        cache.removeAll()
    }

    private func ensureCleanupTaskStarted() {
        guard cacheCleanupTask == nil else {
            return
        }

        // clear cache once / day
        cacheCleanupTask = Task { [weak self] in
            while let self, !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 86_400_000_000_000)
                await self.clearCache()
            }
        }
    }

    func data(for url: URL) async throws -> Data {
        ensureCleanupTaskStarted()

        if let data = cache[url] {
            return data
        }

        if let task = inFlight[url] {
            return try await task.value
        }

        let task = Task<Data, Error> {
            let (data, _) = try await URLSession.shared.data(from: url)
            return data
        }
        inFlight[url] = task

        do {
            let data = try await task.value
            cache[url] = data
            inFlight[url] = nil
            return data
        } catch {
            inFlight[url] = nil
            throw error
        }
    }
}

extension Endpoint {
    public static func latestCityPageWeather(forSite site: Site) async throws -> Endpoint {
        let languageComponent = NSLocale.language == .french ? "fr" : "en"
        let hour = Calendar(identifier: .gregorian).component(.hour, from: Date().addingTimeInterval(-TimeInterval(TimeZone.current.secondsFromGMT())))
        let utcHour = String(format: "%02d", hour)
        let baseURLString = "https://dd.weather.gc.ca/today/citypage_weather/\(site.provinceCode.uppercased())/\(utcHour)/"
        guard let indexURL = URL(string: baseURLString) else {
            throw URLError(.badURL)
        }

        let data = try await URLDataCache.shared.data(for: indexURL)
        guard let html = String(data: data, encoding: .utf8) else {
            throw URLError(.cannotDecodeContentData)
        }

        // Match href XML files that contain the site code and language component, ending in ".xml"
        let pattern = #"href="([^"]*CitypageWeather_\#(site.code)_\#(languageComponent)\.xml)""#
        let regex = try NSRegularExpression(pattern: pattern)

        let matches = regex.matches(in: html, range: NSRange(html.startIndex..., in: html))
        let filenames = matches.compactMap { match -> String? in
            guard match.numberOfRanges > 1,
                  let range = Range(match.range(at: 1), in: html) else {
                return nil
            }
            return String(html[range])
        }

        guard let latest = filenames.sorted().last else {
            throw NSError(domain: "EndpointError", code: 404, userInfo: [NSLocalizedDescriptionKey: "No matching city page file found"])
        }

        let path = "/today/citypage_weather/\(site.provinceCode.uppercased())/\(utcHour)/\(latest)"
        return Endpoint(host: .datamart, path: path)
    }
}
