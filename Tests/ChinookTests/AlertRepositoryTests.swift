import Foundation
import Testing
@testable import Chinook

private let freezingRain3 = "T_WWCN11_C_CWNT_202611052018_2582202182.cap"
private let freezingRain1 = "T_WWCN11_C_CWNT_202611051400_2708143281.cap"
private let freezingRain2 = "T_WWCN11_C_CWNT_202611051610_1829809875.cap"
private let wind = "T_WWCN13_C_CWVR_202611051918_1924134800.cap"

private func capURL(_ station: String, _ hour: String, _ file: String, day: String = "20261105") -> String {
    "https://dd.weather.gc.ca/today/alerts/cap/\(day)/\(station)/\(hour)/\(file)"
}

/// A transport that knows today's alerts: freezing rain updates for CWNT, wind for CWVR, nothing elsewhere.
private func alertTransport() throws -> FakeTransport {
    let transport = FakeTransport()
    transport.stubEverythingElse(body: capListing())
    transport.stub("https://dd.weather.gc.ca/today/alerts/cap/20261105/CWNT/14", body: capListing(freezingRain1, "readme.txt"))
    transport.stub("https://dd.weather.gc.ca/today/alerts/cap/20261105/CWNT/16", body: capListing(freezingRain2))
    transport.stub("https://dd.weather.gc.ca/today/alerts/cap/20261105/CWNT/20", body: capListing(freezingRain3))
    transport.stub("https://dd.weather.gc.ca/today/alerts/cap/20261105/CWVR/19", body: capListing(wind))
    transport.stub(capURL("CWNT", "14", freezingRain1), body: try fixtureString("alert-freezing-rain-1.cap"))
    transport.stub(capURL("CWNT", "16", freezingRain2), body: try fixtureString("alert-freezing-rain-2.cap"))
    transport.stub(capURL("CWNT", "20", freezingRain3), body: try fixtureString("alert-freezing-rain-3.cap"))
    transport.stub(capURL("CWVR", "19", wind), body: try fixtureString("alert-wind-chilcotin.cap"))
    return transport
}

@Suite struct AlertRepositoryTests {
    // MARK: - Manifest

    @Test func aManifestListsOnlyCapFilesAsFullURLs() async throws {
        try await withCacheDirectory { directory in
            let transport = FakeTransport()
            transport.stub("https://dd.weather.gc.ca/today/alerts/cap/20261105/CWNT/20", body: capListing(freezingRain3, "index.html"))
            let loader = makeLoader(transport, cacheDirectory: directory)

            let urls = try await AlertRepository.fetchManifest(forStationCode: "CWNT", day: "20261105", hour: "20", strategy: .networkOnly, loader: loader)

            #expect(urls == [URL(string: capURL("CWNT", "20", freezingRain3))!])
        }
    }

    @Test func aManifestThatIsNotTextIsEmpty() async throws {
        try await withCacheDirectory { directory in
            let transport = FakeTransport()
            transport.stub("https://dd.weather.gc.ca/today/alerts/cap/20261105/CWNT/20", body: "")
            let loader = makeLoader(transport, cacheDirectory: directory)
            // Not valid UTF-8, so it can't be read as a listing.
            try Data([0xFF, 0xFE, 0xFD]).write(to: { () -> URL in
                let url = loader.storageURL(for: Endpoint.alertsManifest(stationCode: "CWNT", day: "20261105", hour: "20"))
                try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
                return url
            }())

            let urls = try await AlertRepository.fetchManifest(forStationCode: "CWNT", day: "20261105", hour: "20", strategy: .diskOnly, loader: loader)

            #expect(urls.isEmpty)
        }
    }

    @Test func aManifestThatCantBeFetchedThrows() async throws {
        try await withCacheDirectory { directory in
            let loader = makeLoader(FakeTransport(), cacheDirectory: directory)

            await #expect(throws: URLError.self) {
                try await AlertRepository.fetchManifest(forStationCode: "CWNT", day: "20261105", hour: "20", strategy: .networkOnly, loader: loader)
            }
        }
    }

    // MARK: - Manifests across two days

    @Test func everyStationAndHourOfTwoDaysIsListed() async throws {
        try await withCacheDirectory { directory in
            let transport = try alertTransport()
            let loader = makeLoader(transport, cacheDirectory: directory)

            let urls = try await AlertRepository.fetchManifests(strategy: .networkOnly, now: utc(hour: 20, minute: 30), loader: loader)

            // 6 stations x (24 hours yesterday + hours 00...20 today)
            #expect(transport.requests.count == 6 * (24 + 21))
            #expect(urls.map(\.lastPathComponent) == [freezingRain1, freezingRain2, freezingRain3, wind].sorted())
        }
    }

    @Test func pastHoursAreServedFromDiskButRecentHoursAlwaysRefresh() async throws {
        try await withCacheDirectory { directory in
            let transport = try alertTransport()
            let loader = makeLoader(transport, cacheDirectory: directory)
            let now = utc(hour: 20, minute: 30)

            _ = try await AlertRepository.fetchManifests(strategy: .diskWithNetworkFallback, now: now, loader: loader)
            let firstRun = transport.requests.count
            _ = try await AlertRepository.fetchManifests(strategy: .diskWithNetworkFallback, now: now, loader: loader)

            #expect(firstRun == 6 * (24 + 21))
            // Second run: only the current and previous hour (19 and 20) of each station.
            #expect(transport.requests.count - firstRun == 6 * 2)
        }
    }

    @Test func justAfterMidnightTheLastHourOfYesterdayIsStillRecent() async throws {
        try await withCacheDirectory { directory in
            let transport = try alertTransport()
            let loader = makeLoader(transport, cacheDirectory: directory)
            let now = utc(hour: 0, minute: 30, day: 6)

            _ = try await AlertRepository.fetchManifests(strategy: .diskWithNetworkFallback, now: now, loader: loader)
            let firstRun = transport.requests.count
            _ = try await AlertRepository.fetchManifests(strategy: .diskWithNetworkFallback, now: now, loader: loader)

            #expect(firstRun == 6 * (24 + 1))
            // Yesterday's hour 23 and today's hour 00.
            #expect(transport.requests.count - firstRun == 6 * 2)
            #expect(transport.requests.contains { $0.absoluteString.contains("/20261105/CWNT/23") })
            #expect(transport.requests.contains { $0.absoluteString.contains("/20261106/CWNT/00") })
        }
    }

    @Test func diskOnlyNeverTouchesTheNetwork() async throws {
        try await withCacheDirectory { directory in
            let transport = try alertTransport()
            let loader = makeLoader(transport, cacheDirectory: directory)

            let urls = try await AlertRepository.fetchManifests(strategy: .diskOnly, now: utc(hour: 20), loader: loader)

            #expect(urls.isEmpty)
            #expect(transport.requests.isEmpty)
        }
    }

    @Test func unlistableDirectoriesContributeNothing() async throws {
        try await withCacheDirectory { directory in
            let loader = makeLoader(FakeTransport(), cacheDirectory: directory)

            let urls = try await AlertRepository.fetchManifests(strategy: .networkOnly, now: utc(hour: 5), loader: loader)

            #expect(urls.isEmpty)
        }
    }

    @Test func cancelledManifestsStopBeforeStarting() async throws {
        try await withCacheDirectory { directory in
            let loader = makeLoader(try alertTransport(), cacheDirectory: directory)

            let task = Task {
                withUnsafeCurrentTask { $0?.cancel() }
                return try await AlertRepository.fetchManifests(strategy: .networkOnly, now: utc(hour: 5), loader: loader)
            }

            await #expect(throws: CancellationError.self) { try await task.value }
        }
    }

    // MARK: - Alerts and advisories

    @Test func anAlertIsFetchedAndDecoded() async throws {
        try await withCacheDirectory { directory in
            let loader = makeLoader(try alertTransport(), cacheDirectory: directory)

            let alert = try await AlertRepository.fetchAlert(from: URL(string: capURL("CWNT", "20", freezingRain3))!, strategy: .networkOnly, loader: loader)

            #expect(alert.info.count == 2)
        }
    }

    @Test func anAlertThatIsNotXMLFailsToDecode() async throws {
        try await withCacheDirectory { directory in
            let transport = FakeTransport()
            transport.stub(capURL("CWNT", "20", "bad.cap"), body: "not xml")
            let loader = makeLoader(transport, cacheDirectory: directory)

            await #expect(throws: (any Error).self) {
                try await AlertRepository.fetchAlert(from: URL(string: capURL("CWNT", "20", "bad.cap"))!, strategy: .networkOnly, loader: loader)
            }
        }
    }

    @Test func advisoriesIgnoreUrlsThatFail() async throws {
        try await withCacheDirectory { directory in
            let loader = makeLoader(try alertTransport(), cacheDirectory: directory)
            let urls = [
                capURL("CWNT", "14", freezingRain1), capURL("CWNT", "16", freezingRain2), capURL("CWNT", "20", freezingRain3),
                capURL("CWVR", "19", wind), capURL("CWNT", "20", "missing.cap")
            ].map { URL(string: $0)! }

            let advisories = try await AlertRepository.fetchAdvisories(
                fromUrls: urls, language: .english, strategy: .networkOnly, now: utc(hour: 21), loader: loader
            )

            #expect(advisories.count == 2)
        }
    }

    @Test func noUrlsMeanNoAdvisories() async throws {
        try await withCacheDirectory { directory in
            let loader = makeLoader(FakeTransport(), cacheDirectory: directory)

            let advisories = try await AlertRepository.fetchAdvisories(fromUrls: [], language: .english, strategy: .networkOnly, now: utc(hour: 21), loader: loader)

            #expect(advisories.isEmpty)
        }
    }

    @Test func cancelledAdvisoriesStopBeforeStarting() async throws {
        try await withCacheDirectory { directory in
            let loader = makeLoader(try alertTransport(), cacheDirectory: directory)

            let task = Task {
                withUnsafeCurrentTask { $0?.cancel() }
                return try await AlertRepository.fetchAdvisories(
                    fromUrls: [URL(string: capURL("CWNT", "20", freezingRain3))!], language: .english, strategy: .networkOnly, now: utc(hour: 21), loader: loader
                )
            }

            await #expect(throws: CancellationError.self) { try await task.value }
        }
    }

    @Test func fetchingEverythingPostsTheAdvisories() async throws {
        try await withCacheDirectory { directory in
            let loader = makeLoader(try alertTransport(), cacheDirectory: directory)
            let posted = Posted<[Advisory]>()
            let token = NotificationCenter.default.addObserver(forName: AlertRepository.Notifications.advisoriesUpdated, object: nil, queue: nil) {
                posted.set($0.object as? [Advisory])
            }
            defer { NotificationCenter.default.removeObserver(token) }

            let advisories = try await AlertRepository.fetchAdvisories(now: utc(hour: 21), loader: loader)

            #expect(advisories.count == 2)
            #expect(posted.value?.count == 2)
        }
    }

    // MARK: - Endpoints

    @Test func anAlertEndpointKeepsTheSchemeAndHostOfItsURL() {
        let secure = Endpoint.alert(url: URL(string: "https://dd.weather.gc.ca/today/alerts/cap/x.cap")!)
        let plain = Endpoint.alert(url: URL(string: "http://example.test/y.cap")!)
        let hostless = Endpoint(url: URL(string: "file:///y.cap")!)

        #expect(secure.url?.absoluteString == "https://dd.weather.gc.ca/today/alerts/cap/x.cap")
        #expect(plain.host.scheme == "http")
        #expect(hostless.host.hostname == "")
    }

    @Test func theNotificationNameIsStable() {
        #expect(AlertRepository.Notifications.advisoriesUpdated.rawValue == "com.thefloorislava.retroweather.AlertRepository.advisoriesUpdated")
    }
}

/// Captures the last value delivered to a notification observer.
final class Posted<T>: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: T?

    func set(_ value: T?) { lock.withLock { stored = value } }
    var value: T? { lock.withLock { stored } }
}
