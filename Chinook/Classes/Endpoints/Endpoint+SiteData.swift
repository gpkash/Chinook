//
//  Endpoint+SiteData.swift
//  Chinook
//
//  Created by Gary Kash on 2020-02-22.
//

import Foundation

extension Endpoint {
    public static func latestCityPageWeather(forSite site: Site) async throws -> Endpoint {
        let languageComponent = NSLocale.language == .french ? "fr" : "en"
        let hour = Calendar(identifier: .gregorian).component(.hour, from: Date().addingTimeInterval(-TimeInterval(TimeZone.current.secondsFromGMT())))
        let utcHour = String(format: "%02d", hour)
        let baseURLString = "https://dd.weather.gc.ca/citypage_weather/\(site.provinceCode.uppercased())/\(utcHour)/"
        guard let indexURL = URL(string: baseURLString) else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: indexURL)
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

        let path = "/citypage_weather/\(site.provinceCode.uppercased())/\(utcHour)/\(latest)"
        return Endpoint(host: .datamart, path: path)
    }
}
