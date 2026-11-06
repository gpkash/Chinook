import Foundation
import Testing
@testable import Chinook

private func citypage(_ name: String) throws -> SiteData {
    try SiteData.decode(fromXML: try fixture(name))
}

private func stations() throws -> ClimateStations {
    ClimateStations(csv: try fixture("climate-station-list.csv"))
}

@Suite struct ClimateStationsTests {
    // MARK: - Reading the list

    @Test func everyStationWithAKnownProvinceIsRead() throws {
        let list = try stations()

        #expect(list.stations.count == 9)
        #expect(list.stations.first { $0.climateID == "5023227" }?.name == "WINNIPEG INTL A")
        #expect(list.stations.first { $0.climateID == "5023227" }?.province == .manitoba)
        #expect(list.stations.first { $0.climateID == "8300301" }?.province == .priceEdwardIsland)
    }

    @Test func aStationKnowsTheYearsItReportedDaily() throws {
        let richardson = try #require(try stations().stations.first { $0.climateID == "5023222" })

        #expect(richardson.dailyYears == 1938...2008)
        #expect(richardson.reportsDaily(in: 1986))
        #expect(!richardson.reportsDaily(in: 2009))
    }

    @Test func aStationThatNeverReportedDailyHasNoYears() {
        let csv = """
        "Station Name","Province","Latitude","Longitude","Elevation","Climate ID","WMO Identifier","TC Identifier","First Year","Last Year","HLY First Year","HLY Last Year","DLY First Year","DLY Last Year","MLY First Year","MLY Last Year"
        "SOMEWHERE","MANITOBA","50.00","-97.00","200.00","5029999","","","1990","1995","","","","","1990","1995",
        """
        let station = ClimateStations(csv: Data(csv.utf8)).stations.first

        #expect(station?.dailyYears == nil)
        #expect(station?.reportsDaily(in: 1992) == false)
    }

    @Test func rowsWithoutAKnownProvinceOrPositionAreSkipped() {
        let csv = """
        "Station Name","Province","Latitude","Longitude","Elevation","Climate ID","WMO Identifier","TC Identifier","First Year","Last Year","HLY First Year","HLY Last Year","DLY First Year","DLY Last Year","MLY First Year","MLY Last Year"
        "NOWHERE","ATLANTIS","50.00","-97.00","200.00","1","","","1990","1995","","","1990","1995","","",
        "NO POSITION","MANITOBA","","","200.00","2","","","1990","1995","","","1990","1995","","",
        "FINE","MANITOBA","50.00","-97.00","200.00","3","","","1990","1995","","","1990","1995","","",
        """

        #expect(ClimateStations(csv: Data(csv.utf8)).stations.map(\.climateID) == ["3"])
    }

    // MARK: - Distance

    @Test func distanceIsGreatCircleKilometres() throws {
        let list = try stations()
        let airport = try #require(list.stations.first { $0.climateID == "5023227" })

        // The airport to The Forks is about 8 km.
        #expect(abs(airport.kilometres(fromLatitude: 49.89, longitude: -97.13) - 8.2) < 0.3)
        #expect(airport.kilometres(fromLatitude: airport.latitude, longitude: airport.longitude) == 0)
    }

    // MARK: - Finding the station for a site and year

    /// Winnipeg's observing airport is `5023227` now, and was `5023222` when the 1987 screen was made.
    @Test func theStationDependsOnTheYear() throws {
        let winnipeg = try citypage("citypage-winnipeg-en.xml")
        let list = try stations()

        #expect(list.station(for: winnipeg, year: 2025)?.climateID == "5023227")
        #expect(list.station(for: winnipeg, year: 1986)?.climateID == "5023222")
    }

    @Test func aNeighbouringStationFillsAYearTheNearestOneMissed() throws {
        // 5023222 stopped in 2008 and 5023227 only began in 2018; 502S001 covers the years between.
        let winnipeg = try citypage("citypage-winnipeg-en.xml")

        #expect(try stations().station(for: winnipeg, year: 2010)?.climateID == "502S001")
    }

    /// The city page's own position is downtown, near The Forks; the airport is what people mean by "Winnipeg".
    @Test func theObservingStationIsPreferredToTheSitesOwnPosition() throws {
        let winnipeg = try citypage("citypage-winnipeg-en.xml")
        let list = try stations()

        #expect(list.station(nearLatitude: 49.89, longitude: -97.13, year: 2025)?.climateID == "5023262")
        #expect(list.station(for: winnipeg, year: 2025)?.climateID == "5023227")
    }

    @Test func aSiteWithNoStationReportingFallsBackToItsOwnPosition() throws {
        let valemount = try citypage("citypage-valemount-no-observation.xml")
        let csv = """
        "Station Name","Province","Latitude","Longitude","Elevation","Climate ID","WMO Identifier","TC Identifier","First Year","Last Year","HLY First Year","HLY Last Year","DLY First Year","DLY Last Year","MLY First Year","MLY Last Year"
        "VALEMOUNT","BRITISH COLUMBIA","53.31","-120.17","800.00","1168520","","","1970","2026","","","1970","2026","","",
        """

        #expect(valemount.observationPoint == nil)
        #expect(ClimateStations(csv: Data(csv.utf8)).station(for: valemount, year: 2025)?.climateID == "1168520")
    }

    @Test func noStationIsFoundForAYearNobodyReported() throws {
        // Edmonton Blatchford began in 1996.
        #expect(try stations().station(for: try citypage("citypage-edmonton-en.xml"), year: 1990) == nil)
    }

    @Test func aStationTooFarAwayIsNotUsed() throws {
        let list = try stations()

        #expect(list.station(nearLatitude: 49.91, longitude: -97.24, year: 2025, maxKilometres: 0.5)?.climateID == "5023227")
        #expect(list.station(nearLatitude: 49.5, longitude: -97.24, year: 2025, maxKilometres: 25) == nil)
    }

    // MARK: - Positions

    @Test func positionsAreReadFromEcsCoordinateStrings() throws {
        let winnipeg = try citypage("citypage-winnipeg-en.xml")

        #expect(winnipeg.point == CGPoint(latitude: 49.89, longitude: -97.13))
        #expect(winnipeg.observationPoint == CGPoint(latitude: 49.91, longitude: -97.24))
        #expect(CGPoint(ecLatitude: "33.9S", longitude: "18.4E") == CGPoint(latitude: -33.9, longitude: 18.4))
        #expect(CGPoint(ecLatitude: "north", longitude: "west") == nil)
    }
}

@Suite struct ClimateStationRepositoryTests {
    private static let listURL = "https://dd.weather.gc.ca/today/climate/observations/climate_station_list.csv"

    private func transport() throws -> FakeTransport {
        let transport = FakeTransport()
        transport.stub(Self.listURL, body: try fixtureString("climate-station-list.csv"))
        return transport
    }

    @Test func aSitesStationIsFoundForTheYear() async throws {
        try await withCacheDirectory { directory in
            let loader = makeLoader(try transport(), cacheDirectory: directory)
            let winnipeg = try citypage("citypage-winnipeg-en.xml")

            let now = try await ClimateRepository.fetchClimateStation(forSiteData: winnipeg, year: 2025, strategy: .networkOnly, loader: loader)
            let then = try await ClimateRepository.fetchClimateStation(forSiteData: winnipeg, year: 1986, strategy: .networkOnly, loader: loader)

            #expect(now.climateID == "5023227")
            #expect(then.climateID == "5023222")
            #expect(then.province == .manitoba)
        }
    }

    @Test func aYearWithNoStationThrowsAClearError() async throws {
        try await withCacheDirectory { directory in
            let loader = makeLoader(try transport(), cacheDirectory: directory)
            let edmonton = try citypage("citypage-edmonton-en.xml")

            await #expect(throws: ClimateError.noClimateStation(siteName: "Edmonton", year: 1990)) {
                try await ClimateRepository.fetchClimateStation(forSiteData: edmonton, year: 1990, strategy: .networkOnly, loader: loader)
            }
        }
    }

    @Test func theStationListIsKeptOnDiskForNextTime() async throws {
        try await withCacheDirectory { directory in
            let transport = try transport()
            let loader = makeLoader(transport, cacheDirectory: directory)
            let winnipeg = try citypage("citypage-winnipeg-en.xml")

            _ = try await ClimateRepository.fetchClimateStation(forSiteData: winnipeg, year: 2025, strategy: .diskWithNetworkFallback, loader: loader)
            transport.stubEverythingElse(status: 500)
            let again = try await ClimateRepository.fetchClimateStation(forSiteData: winnipeg, year: 2025, strategy: .diskOnly, loader: loader)

            #expect(again.climateID == "5023227")
        }
    }

    @Test func cancelledFetchesStopBeforeStarting() async throws {
        try await withCacheDirectory { directory in
            let transport = try transport()
            let loader = makeLoader(transport, cacheDirectory: directory)
            let winnipeg = try citypage("citypage-winnipeg-en.xml")

            let task = Task {
                withUnsafeCurrentTask { $0?.cancel() }
                return try await ClimateRepository.fetchClimateStation(forSiteData: winnipeg, year: 2025, strategy: .networkOnly, loader: loader)
            }

            await #expect(throws: CancellationError.self) { try await task.value }
            #expect(transport.requests.isEmpty)
        }
    }
}
