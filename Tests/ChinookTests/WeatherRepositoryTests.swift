import Foundation
import Testing
@testable import Chinook

private let edmonton = Site(code: "s0000045", nameEn: "Edmonton", nameFr: "Edmonton", provinceCode: "AB")
private let winnipeg = Site(code: "s0000193", nameEn: "Winnipeg", nameFr: "Winnipeg", provinceCode: "MB")
private let unpublished = Site(code: "s0000777", nameEn: "Unpublished", nameFr: "Unpublished", provinceCode: "AB")

private let edmontonFiles = (en: "20261105T200055.888Z_MSC_CitypageWeather_s0000045_en.xml", fr: "20261105T200055.937Z_MSC_CitypageWeather_s0000045_fr.xml")
private let winnipegFiles = (en: "20261105T200100.100Z_MSC_CitypageWeather_s0000193_en.xml", fr: "20261105T200100.200Z_MSC_CitypageWeather_s0000193_fr.xml")

/// EC for hour 20: listings for Alberta and Manitoba, and the Edmonton and Winnipeg pages in both languages.
private func ecTransport() throws -> FakeTransport {
    let transport = FakeTransport()
    let base = "https://dd.weather.gc.ca/today/citypage_weather"
    transport.stub("\(base)/AB/20/", body: capListing(edmontonFiles.en, edmontonFiles.fr))
    transport.stub("\(base)/MB/20/", body: capListing(winnipegFiles.en, winnipegFiles.fr))
    transport.stub("\(base)/AB/20/\(edmontonFiles.en)", body: try fixtureString("citypage-edmonton-en.xml"))
    transport.stub("\(base)/AB/20/\(edmontonFiles.fr)", body: try fixtureString("citypage-edmonton-fr.xml"))
    transport.stub("\(base)/MB/20/\(winnipegFiles.en)", body: try fixtureString("citypage-winnipeg-en.xml"))
    transport.stub("\(base)/MB/20/\(winnipegFiles.fr)", body: try fixtureString("citypage-winnipeg-en.xml"))
    transport.stub("\(base)/siteList.xml", body: try fixtureString("sitelist.xml"))
    return transport
}

private func locator(_ loader: DataLoader) -> CityPageLocator {
    CityPageLocator(now: { utc(hour: 20, minute: 30) }, fetchListing: { try await loader.request($0, strategy: .networkOnly).data })
}

@Suite struct WeatherRepositoryTests {
    @Test func aSiteIsLocatedFetchedDecodedAndPosted() async throws {
        try await withCacheDirectory { directory in
            let loader = makeLoader(try ecTransport(), cacheDirectory: directory)
            let posted = Posted<SiteData>()
            let token = NotificationCenter.default.addObserver(forName: edmonton.siteDataUpdatedNotification, object: nil, queue: nil) {
                posted.set($0.siteData)
            }
            defer { NotificationCenter.default.removeObserver(token) }

            let siteData = try await WeatherRepository.fetchWeather(forSite: edmonton, strategy: .networkOnly, loader: loader, locator: locator(loader))

            #expect(siteData.location.name.value == "Edmonton")
            #expect(posted.value?.location.name.value == "Edmonton")
        }
    }

    @Test func aSiteThatIsNotPublishedFails() async throws {
        try await withCacheDirectory { directory in
            let loader = makeLoader(try ecTransport(), cacheDirectory: directory)

            await #expect(throws: (any Error).self) {
                try await WeatherRepository.fetchWeather(forSite: unpublished, strategy: .networkOnly, loader: loader, locator: locator(loader))
            }
        }
    }

    @Test func cancelledFetchesStopBeforeStarting() async throws {
        try await withCacheDirectory { directory in
            let loader = makeLoader(try ecTransport(), cacheDirectory: directory)
            let locator = locator(loader)

            let single = Task {
                withUnsafeCurrentTask { $0?.cancel() }
                return try await WeatherRepository.fetchWeather(forSite: edmonton, strategy: .networkOnly, loader: loader, locator: locator)
            }
            let several = Task {
                withUnsafeCurrentTask { $0?.cancel() }
                return try await WeatherRepository.fetchWeather(forSites: [edmonton], strategy: .networkOnly, loader: loader, locator: locator)
            }

            await #expect(throws: CancellationError.self) { try await single.value }
            await #expect(throws: CancellationError.self) { try await several.value }
        }
    }

    // MARK: - Several sites

    @Test func severalSitesComeBackInOrder() async throws {
        try await withCacheDirectory { directory in
            let loader = makeLoader(try ecTransport(), cacheDirectory: directory)

            let results = try await WeatherRepository.fetchWeather(forSites: [winnipeg, edmonton], strategy: .networkOnly, loader: loader, locator: locator(loader))

            #expect(results.map { $0.location.name.value } == ["Winnipeg", "Edmonton"])
        }
    }

    @Test func oneFailingSiteDoesNotCostTheOthers() async throws {
        try await withCacheDirectory { directory in
            let loader = makeLoader(try ecTransport(), cacheDirectory: directory)

            let results = try await WeatherRepository.fetchWeather(forSites: [edmonton, unpublished, winnipeg], strategy: .networkOnly, loader: loader, locator: locator(loader))

            #expect(results.map { $0.location.name.value } == ["Edmonton", "Winnipeg"])
        }
    }

    @Test func ifEverySiteFailsTheFirstErrorIsThrown() async throws {
        try await withCacheDirectory { directory in
            let loader = makeLoader(try ecTransport(), cacheDirectory: directory)

            await #expect(throws: (any Error).self) {
                try await WeatherRepository.fetchWeather(forSites: [unpublished], strategy: .networkOnly, loader: loader, locator: locator(loader))
            }
        }
    }

    @Test func noSitesMeansNoWork() async throws {
        try await withCacheDirectory { directory in
            let transport = try ecTransport()
            let loader = makeLoader(transport, cacheDirectory: directory)

            let results = try await WeatherRepository.fetchWeather(forSites: [], strategy: .networkOnly, loader: loader, locator: locator(loader))

            #expect(results.isEmpty)
            #expect(transport.requests.isEmpty)
        }
    }

    // MARK: - Site list

    @Test func theSiteListIsFetchedDecodedAndPosted() async throws {
        try await withCacheDirectory { directory in
            let loader = makeLoader(try ecTransport(), cacheDirectory: directory)
            let posted = Posted<SiteList>()
            let token = NotificationCenter.default.addObserver(forName: WeatherRepository.Notifications.siteListUpdated, object: nil, queue: nil) {
                posted.set($0.siteList)
            }
            defer { NotificationCenter.default.removeObserver(token) }

            let siteList = try await WeatherRepository.fetchCityPageSiteList(strategy: .networkOnly, loader: loader)

            #expect(siteList.sites.count == 8)
            #expect(posted.value?.sites.count == 8)
        }
    }

    @Test func aCancelledSiteListFetchStopsBeforeStarting() async throws {
        try await withCacheDirectory { directory in
            let loader = makeLoader(try ecTransport(), cacheDirectory: directory)

            let task = Task {
                withUnsafeCurrentTask { $0?.cancel() }
                return try await WeatherRepository.fetchCityPageSiteList(strategy: .networkOnly, loader: loader)
            }

            await #expect(throws: CancellationError.self) { try await task.value }
        }
    }

    // MARK: - Typed notification payloads

    @Test func notificationsExposeTheirPayloadByType() throws {
        let siteData = try SiteData.decode(fromXML: fixture("citypage-edmonton-en.xml"))
        let siteList = try SiteList.decode(fromXML: fixture("sitelist.xml"))
        let advisories: [Advisory] = []

        #expect(Notification(name: .init("x"), object: siteData).siteData != nil)
        #expect(Notification(name: .init("x"), object: siteList).siteList != nil)
        #expect(Notification(name: .init("x"), object: advisories).advisories != nil)
        #expect(Notification(name: .init("x"), object: "other").siteData == nil)
        #expect(Notification(name: .init("x"), object: nil).advisories == nil)
    }

    @Test func theSiteNotificationNameIsPerSite() {
        #expect(edmonton.siteDataUpdatedNotification.rawValue == "com.thefloorislava.retroweather.Site.SiteDataUpdateds0000045")
        #expect(edmonton.siteDataUpdatedNotification != winnipeg.siteDataUpdatedNotification)
    }
}
