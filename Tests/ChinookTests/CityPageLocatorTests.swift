import Foundation
import Testing
@testable import Chinook

private let edmonton = Site(code: "s0000045", nameEn: "Edmonton", nameFr: "Edmonton", provinceCode: "ab")

private func listing(_ files: String...) -> Data {
    Data(files.map { "<a href=\"\($0)\">\($0)</a> 2026-11-05 20:01 33K" }.joined(separator: "\n").utf8)
}

private func date(hour: Int) -> Date {
    var components = DateComponents(year: 2026, month: 11, day: 5, hour: hour, minute: 30)
    components.timeZone = TimeZone(secondsFromGMT: 0)
    return Calendar(identifier: .gregorian).date(from: components)!
}

/// A fetcher that serves listings by directory path and counts requests.
private final class Listings: @unchecked Sendable {
    private let lock = NSLock()
    private var byPath: [String: Result<Data, Error>] = [:]
    private var paths: [String] = []
    var delay: Duration = .zero

    func set(_ path: String, _ data: Data) { lock.withLock { byPath[path] = .success(data) } }
    func fail(_ path: String, _ error: Error) { lock.withLock { byPath[path] = .failure(error) } }
    var requested: [String] { lock.withLock { paths } }

    func fetch(_ endpoint: Endpoint) async throws -> Data {
        lock.withLock { paths.append(endpoint.path) }
        if delay > .zero { try await Task.sleep(for: delay) }

        guard let result = lock.withLock({ byPath[endpoint.path] }) else { throw NetworkError.httpError(statusCode: 404) }
        return try result.get()
    }
}

@Suite struct CityPageLocatorTests {
    // MARK: - Listing parser

    @Test func picksTheNewestFileForTheSite() {
        let html = String(decoding: listing(
            "20261105T190100.020Z_MSC_CitypageWeather_s0000045_en.xml",
            "20261105T200055.888Z_MSC_CitypageWeather_s0000045_en.xml",
            "20261105T200055.937Z_MSC_CitypageWeather_s0000045_fr.xml",
            "20261105T200122.901Z_MSC_CitypageWeather_s0000047_en.xml"
        ), as: UTF8.self)

        #expect(CityPageLocator.latestFilename(in: html, siteCode: "s0000045", language: .english)
                == "20261105T200055.888Z_MSC_CitypageWeather_s0000045_en.xml")
        #expect(CityPageLocator.latestFilename(in: html, siteCode: "s0000045", language: .french)
                == "20261105T200055.937Z_MSC_CitypageWeather_s0000045_fr.xml")
    }

    @Test func returnsNilWhenTheSiteIsNotListed() {
        let html = "<a href=\"20261105T200122.901Z_MSC_CitypageWeather_s0000047_en.xml\">x</a>"

        #expect(CityPageLocator.latestFilename(in: html, siteCode: "s0000045", language: .english) == nil)
    }

    @Test func siteCodesAreMatchedLiterally() {
        let html = "<a href=\"20261105T200122.901Z_MSC_CitypageWeather_s0000045_en.xml\">x</a>"

        #expect(CityPageLocator.latestFilename(in: html, siteCode: "s0000.45", language: .english) == nil)
    }

    // MARK: - Locating

    @Test func usesTheCurrentHoursDirectory() async throws {
        let listings = Listings()
        listings.set("/today/citypage_weather/AB/20/", listing("20261105T200055.888Z_MSC_CitypageWeather_s0000045_en.xml"))
        let locator = CityPageLocator(now: { date(hour: 20) }, fetchListing: listings.fetch)

        let endpoint = try await locator.latestEndpoint(for: edmonton, language: .english)

        #expect(endpoint.path == "/today/citypage_weather/AB/20/20261105T200055.888Z_MSC_CitypageWeather_s0000045_en.xml")
        #expect(endpoint.host.hostname == "dd.weather.gc.ca")
        #expect(listings.requested == ["/today/citypage_weather/AB/20/"])
    }

    @Test func fallsBackToThePreviousHourWhenTheSiteIsNotPublishedYet() async throws {
        let listings = Listings()
        listings.set("/today/citypage_weather/AB/20/", listing("20261105T200122.901Z_MSC_CitypageWeather_s0000047_en.xml"))
        listings.set("/today/citypage_weather/AB/19/", listing("20261105T190100.020Z_MSC_CitypageWeather_s0000045_en.xml"))
        let locator = CityPageLocator(now: { date(hour: 20) }, fetchListing: listings.fetch)

        let endpoint = try await locator.latestEndpoint(for: edmonton, language: .english)

        #expect(endpoint.path == "/today/citypage_weather/AB/19/20261105T190100.020Z_MSC_CitypageWeather_s0000045_en.xml")
    }

    @Test func fallsBackWhenTheCurrentHoursDirectoryDoesNotExistYet() async throws {
        let listings = Listings()
        listings.set("/today/citypage_weather/AB/19/", listing("20261105T190100.020Z_MSC_CitypageWeather_s0000045_en.xml"))
        let locator = CityPageLocator(now: { date(hour: 20) }, fetchListing: listings.fetch)

        let endpoint = try await locator.latestEndpoint(for: edmonton, language: .english)

        #expect(endpoint.path.contains("/AB/19/"))
    }

    @Test func hourZeroHasNoPreviousHourToTry() async throws {
        let listings = Listings()
        listings.set("/today/citypage_weather/AB/00/", listing("x"))
        let locator = CityPageLocator(now: { date(hour: 0) }, fetchListing: listings.fetch)

        await #expect(throws: CityPageError.self) {
            try await locator.latestEndpoint(for: edmonton, language: .english)
        }
        #expect(listings.requested == ["/today/citypage_weather/AB/00/"])
    }

    @Test func throwsNotPublishedWhenNoDirectoryHasTheSite() async throws {
        let listings = Listings()
        listings.set("/today/citypage_weather/AB/20/", listing("x"))
        listings.set("/today/citypage_weather/AB/19/", listing("y"))
        let locator = CityPageLocator(now: { date(hour: 20) }, fetchListing: listings.fetch)

        do {
            _ = try await locator.latestEndpoint(for: edmonton, language: .english)
            Issue.record("expected an error")
        }
        catch let error as CityPageError {
            #expect(error.errorDescription == "No matching city page file found")
        }
    }

    @Test func surfacesTheFirstFetchErrorWhenEveryDirectoryFails() async throws {
        let listings = Listings()
        listings.fail("/today/citypage_weather/AB/20/", URLError(.notConnectedToInternet))
        listings.fail("/today/citypage_weather/AB/19/", URLError(.timedOut))
        let locator = CityPageLocator(now: { date(hour: 20) }, fetchListing: listings.fetch)

        do {
            _ = try await locator.latestEndpoint(for: edmonton, language: .english)
            Issue.record("expected an error")
        }
        catch let error as URLError {
            #expect(error.code == .notConnectedToInternet)
        }
    }

    // MARK: - Listing reuse

    @Test func simultaneousLookupsShareOneListingFetch() async throws {
        let listings = Listings()
        listings.delay = .milliseconds(50)
        listings.set("/today/citypage_weather/AB/20/", listing(
            "20261105T200055.888Z_MSC_CitypageWeather_s0000045_en.xml",
            "20261105T200122.901Z_MSC_CitypageWeather_s0000047_en.xml"
        ))
        let locator = CityPageLocator(now: { date(hour: 20) }, fetchListing: listings.fetch)
        let calgary = Site(code: "s0000047", nameEn: "Calgary", nameFr: "Calgary", provinceCode: "AB")

        async let first = locator.latestEndpoint(for: edmonton, language: .english)
        async let second = locator.latestEndpoint(for: calgary, language: .english)
        let (edmontonEndpoint, calgaryEndpoint) = try await (first, second)

        #expect(edmontonEndpoint.path.contains("s0000045"))
        #expect(calgaryEndpoint.path.contains("s0000047"))
        #expect(listings.requested.count == 1)
    }

    @Test func aListingIsReusedBrieflyThenRefetched() async throws {
        let listings = Listings()
        listings.set("/today/citypage_weather/AB/20/", listing("20261105T200055.888Z_MSC_CitypageWeather_s0000045_en.xml"))
        let clock = Clock()
        let locator = CityPageLocator(now: { clock.now }, listingLifetime: 60, fetchListing: listings.fetch)

        _ = try await locator.latestEndpoint(for: edmonton, language: .english)
        clock.advance(by: 30)
        _ = try await locator.latestEndpoint(for: edmonton, language: .english)
        #expect(listings.requested.count == 1)

        clock.advance(by: 31)
        _ = try await locator.latestEndpoint(for: edmonton, language: .english)
        #expect(listings.requested.count == 2)
    }

    @Test func aFailedFetchIsNotRemembered() async throws {
        let listings = Listings()
        listings.fail("/today/citypage_weather/AB/20/", URLError(.timedOut))
        let locator = CityPageLocator(now: { date(hour: 20) }, fetchListing: listings.fetch)

        _ = try? await locator.latestEndpoint(for: edmonton, language: .english)

        listings.set("/today/citypage_weather/AB/20/", listing("20261105T200055.888Z_MSC_CitypageWeather_s0000045_en.xml"))
        let endpoint = try await locator.latestEndpoint(for: edmonton, language: .english)

        #expect(endpoint.path.contains("s0000045"))
    }
}

private final class Clock: @unchecked Sendable {
    private let lock = NSLock()
    private var current = date(hour: 20)

    var now: Date { lock.withLock { current } }
    func advance(by seconds: TimeInterval) { lock.withLock { current = current.addingTimeInterval(seconds) } }
}
