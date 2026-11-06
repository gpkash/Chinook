import Foundation
import Testing
@testable import Chinook

private func citypage(_ name: String) throws -> SiteData {
    try SiteData.decode(fromXML: try fixture(name))
}

private func stations() throws -> ClimateStations {
    ClimateStations(csv: try fixture("climate-station-list.csv"))
}

private let manitoba = ClimateStation(climateID: "5023227", name: "WINNIPEG INTL A", province: .manitoba, latitude: 49.91, longitude: -97.24, dailyYears: 2018...2026)

private let dailyHeader = #""Longitude (x)","Latitude (y)","Station Name","Climate ID","Date/Time","Year","Month","Day","Data Quality","Max Temp (°C)","Max Temp Flag","Min Temp (°C)","Min Temp Flag","Total Snow (cm)","Total Snow Flag""#

/// A daily file where each tuple is (day, max, min, snow); a nil is a blank field.
private func daily(year: Int = 2026, month: Int = 1, _ days: [(Int, Double?, Double?, Double?)]) -> DailyObservations {
    func field(_ value: Double?) -> String { value.map { "\($0)" } ?? "" }

    let rows = days.map { day, high, low, snow in
        #""-97.24","49.91","X","1","\#(year)-\#(month)-\#(day)","\#(year)","\#(String(format: "%02d", month))","\#(String(format: "%02d", day))","","\#(field(high))","","\#(field(low))","","\#(field(snow))","","#
    }

    return DailyObservations(csv: Data(([dailyHeader] + rows).joined(separator: "\n").utf8))
}

@Suite struct DailyObservationsTests {
    @Test func everyDayInTheFileIsRead() throws {
        let observations = DailyObservations(csv: try fixture("climate-daily-winnipeg-2026.csv"))

        #expect(observations.days.count == 34)
        #expect(observations.days(inMonth: 10).count == 31)
        #expect(observations.days(inMonth: 11).map(\.day) == [1, 2, 3])
    }

    @Test func aDayHoldsItsTemperaturesFromAFileThatIsNotUTF8() throws {
        let day = try #require(DailyObservations(csv: try fixture("climate-daily-winnipeg-2026.csv")).days(inMonth: 10).first)

        #expect(day.year == 2026)
        #expect(day.maxTemperature == 13.1)
        #expect(day.minTemperature == 1.0)
        #expect(day.snowfall == nil)
    }

    @Test func aBlankFieldIsNilNotZero() {
        let day = daily([(1, 5.0, nil, nil)]).days[0]

        #expect(day.maxTemperature == 5.0)
        #expect(day.minTemperature == nil)
    }
}

@Suite struct MonthlyClimateSummaryTests {
    private func summary(_ observations: DailyObservations, year: Int = 2026, month: Int = 1, normals: MonthlyNormals? = nil) -> MonthlyClimateSummary {
        MonthlyClimateSummary(station: manitoba, year: year, month: month, observations: observations, normals: normals)
    }

    @Test func aMonthIsAveragedWarmestAndColdest() throws {
        let october = summary(DailyObservations(csv: try fixture("climate-daily-winnipeg-2026.csv")), month: 10)

        #expect(october.daysObserved == 31)
        #expect(try abs(#require(october.averageHigh) - 14.2) < 0.05)
        #expect(try abs(#require(october.averageLow) - 1.8) < 0.05)
        #expect(october.warmest == DayTemperature(temperature: 24.6, day: 23))
        #expect(october.coldest == DayTemperature(temperature: -7.0, day: 26))
    }

    @Test func otherMonthsAndYearsAreLeftOut() {
        let observations = DailyObservations(days: [
            DailyObservation(year: 2026, month: 1, day: 1, maxTemperature: 10, minTemperature: 0),
            DailyObservation(year: 2026, month: 2, day: 1, maxTemperature: 99, minTemperature: -99),
            DailyObservation(year: 2025, month: 1, day: 1, maxTemperature: 50, minTemperature: -50)
        ])
        let january = summary(observations)

        #expect(january.averageHigh == 10)
        #expect(january.coldest == DayTemperature(temperature: 0, day: 1))
    }

    @Test func missingDaysDoNotPullTheAverageDown() {
        let january = summary(daily([(1, -10, -20, nil), (2, nil, nil, nil), (3, -12, -22, nil)]))

        #expect(january.daysObserved == 2)
        #expect(january.averageHigh == -11)
        #expect(january.averageLow == -21)
    }

    @Test func aMonthWithNoTemperaturesHasNothingToReport() {
        let january = summary(daily([(1, nil, nil, nil)]))

        #expect(january.daysObserved == 0)
        #expect(january.averageHigh == nil)
        #expect(january.averageLow == nil)
        #expect(january.warmest == nil)
        #expect(january.coldest == nil)
    }

    @Test func theFirstOfTwoEqualDaysIsTheOneReported() {
        let january = summary(daily([(3, 5, -5, nil), (9, 5, -5, nil)]))

        #expect(january.warmest?.day == 3)
        #expect(january.coldest?.day == 3)
    }

    @Test func snowfallIsTotalledWhenTheStationReportsMostDays() {
        let days = (1...31).map { ($0, -10.0, -20.0, $0 == 5 ? Optional(12.5) : Optional(0.0)) }

        #expect(summary(daily(days)).snowfall == 12.5)
    }

    @Test func aStationThatNeverReportsSnowHasNoSnowfall() {
        let days = (1...31).map { ($0, -10.0, -20.0, Double?.none) }

        #expect(summary(daily(days)).snowfall == nil)
    }

    @Test func snowReportedOnFewDaysIsNotBelieved() {
        let days = (1...31).map { ($0, -10.0, -20.0, $0 <= 10 ? Optional(1.0) : nil) }

        #expect(summary(daily(days)).snowfall == nil)
    }

    @Test func aShortMonthNeedsFewerSnowDays() {
        // 23 of February's 28 days is over 80%.
        let days = (1...28).map { ($0, -10.0, -20.0, $0 <= 23 ? Optional(1.0) : nil) }

        #expect(summary(daily(month: 2, days), month: 2).snowfall == 23)
    }

    @Test func theNormalsAreCarriedAlong() {
        let normals = MonthlyNormals(month: 1, averageHigh: -11.3, averageLow: -21.4, snowfall: 23.7)

        #expect(summary(daily([(1, -10, -20, nil)]), normals: normals).normals == normals)
    }
}

@Suite struct ClimateNormalsTests {
    @Test func theMonthsAreReadFromTheirLabelledRows() throws {
        let normals = ClimateNormals(csv: try fixture("climate-normals-winnipeg.csv"))

        #expect(normals.months.map(\.month) == Array(1...12))
        #expect(normals.normals(forMonth: 1) == MonthlyNormals(month: 1, averageHigh: -11.3, averageLow: -21.4, snowfall: 23.7))
        #expect(normals.normals(forMonth: 7) == MonthlyNormals(month: 7, averageHigh: 25.9, averageLow: 13.5, snowfall: 0.0))
        #expect(normals.normals(forMonth: 12)?.averageLow == -17.8)
    }

    @Test func extremesAreNotMistakenForAverages() throws {
        // "Extreme Maximum" and "Extreme Daily Snowfall" sit near the rows that are wanted.
        #expect(try ClimateNormals(csv: fixture("climate-normals-winnipeg.csv")).normals(forMonth: 1)?.averageHigh == -11.3)
    }

    @Test func aRowThatIsMissingLeavesItsValuesNil() {
        let csv = """
        " ","Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec","Year","Code"
        "Daily Maximum (°C)","-1.0","","","","","","","","","","","","","A"
        """
        let january = ClimateNormals(csv: Data(csv.utf8)).normals(forMonth: 1)

        #expect(january == MonthlyNormals(month: 1, averageHigh: -1.0))
        #expect(ClimateNormals(csv: Data(csv.utf8)).normals(forMonth: 2)?.averageHigh == nil)
    }

    @Test func aFileThatIsNotNormalsHasNoMonths() {
        #expect(ClimateNormals(csv: Data("<html>Not Found</html>".utf8)).months.isEmpty)
        #expect(ClimateNormals(csv: Data()).normals(forMonth: 1) == nil)
    }
}

@Suite struct NormalsStationsTests {
    @Test func aStationNeedsFifteenYearsOfMonthlyDataIn1981To2010() throws {
        let list = try stations()
        func likely(_ id: String) -> Bool { list.stations.first { $0.climateID == id }?.likelyHasNormals ?? false }

        #expect(likely("5023222"))      // 1938–2007
        #expect(likely("5022791"))      // 1972–2007
        #expect(!likely("502S001"))     // 1996–2007: twelve years
        #expect(!likely("5023227"))     // no monthly data
        #expect(!likely("3012216"))
    }

    /// Winnipeg's airport reports daily now, but its normals were built from the airport it replaced.
    @Test func theNearestStationWithNormalsIsNotTheObservingOne() throws {
        let winnipeg = try citypage("citypage-winnipeg-en.xml")

        #expect(try stations().normalsStations(for: winnipeg).map(\.climateID) == ["5023222", "5022791"])
    }

    @Test func theLimitAndTheDistanceAreRespected() throws {
        let winnipeg = try citypage("citypage-winnipeg-en.xml")

        #expect(try stations().normalsStations(for: winnipeg, limit: 1).map(\.climateID) == ["5023222"])
        #expect(try stations().normalsStations(for: winnipeg, maxKilometres: 5).map(\.climateID) == ["5023222"])
    }
}

@Suite struct MonthlySummaryRepositoryTests {
    private static let listURL = "https://dd.weather.gc.ca/today/climate/observations/climate_station_list.csv"
    private static let dailyURL = "https://dd.weather.gc.ca/today/climate/observations/daily/csv/MB/climate_daily_MB_5023227_2026_P1D.csv"
    private static let richardsonNormalsURL = "https://dd.weather.gc.ca/today/climate/observations/normals/csv/1981-2010/MB/climate_normals_MB_5023222_1981-2010.csv"
    private static let stonyMountainNormalsURL = "https://dd.weather.gc.ca/today/climate/observations/normals/csv/1981-2010/MB/climate_normals_MB_5022791_1981-2010.csv"

    private func transport(richardson: Int = 200) throws -> FakeTransport {
        let transport = FakeTransport()
        transport.stub(Self.listURL, body: try fixtureString("climate-station-list.csv"))
        transport.stub(Self.dailyURL, data: try fixture("climate-daily-winnipeg-2026.csv"))
        transport.stub(Self.richardsonNormalsURL, status: richardson, data: try fixture("climate-normals-winnipeg.csv"))
        return transport
    }

    @Test func aMonthIsSummarisedWithTheNormalsOfTheOlderStation() async throws {
        try await withCacheDirectory { directory in
            let loader = makeLoader(try transport(), cacheDirectory: directory)
            let winnipeg = try citypage("citypage-winnipeg-en.xml")

            let october = try await ClimateRepository.fetchMonthlySummary(forSiteData: winnipeg, year: 2026, month: 10, strategy: .networkOnly, loader: loader)

            #expect(october.station.climateID == "5023227")
            #expect(october.daysObserved == 31)
            #expect(october.warmest == DayTemperature(temperature: 24.6, day: 23))
            #expect(october.snowfall == nil)
            #expect(october.normals == MonthlyNormals(month: 10, averageHigh: 10.5, averageLow: -0.5, snowfall: 4.8))
        }
    }

    @Test func theNextStationIsTriedWhenTheNearestHasNoNormals() async throws {
        try await withCacheDirectory { directory in
            let transport = try transport(richardson: 404)
            transport.stub(Self.stonyMountainNormalsURL, data: try fixture("climate-normals-winnipeg.csv"))
            let loader = makeLoader(transport, cacheDirectory: directory)

            let october = try await ClimateRepository.fetchMonthlySummary(forSiteData: try citypage("citypage-winnipeg-en.xml"), year: 2026, month: 10, strategy: .networkOnly, loader: loader)

            #expect(october.normals?.averageHigh == 10.5)
            #expect(transport.requests.map(\.absoluteString).contains(Self.stonyMountainNormalsURL))
        }
    }

    @Test func aSiteWithoutNormalsStillGetsItsMonth() async throws {
        try await withCacheDirectory { directory in
            let transport = try transport(richardson: 404)
            transport.stub(Self.stonyMountainNormalsURL, status: 404)
            let loader = makeLoader(transport, cacheDirectory: directory)

            let october = try await ClimateRepository.fetchMonthlySummary(forSiteData: try citypage("citypage-winnipeg-en.xml"), year: 2026, month: 10, strategy: .networkOnly, loader: loader)

            #expect(october.normals == nil)
            #expect(october.averageHigh != nil)
        }
    }

    @Test func aServerErrorOnTheDailyFileIsReported() async throws {
        try await withCacheDirectory { directory in
            let transport = try transport()
            transport.stub(Self.dailyURL, status: 404)
            let loader = makeLoader(transport, cacheDirectory: directory)

            await #expect(throws: NetworkError.self) {
                try await ClimateRepository.fetchMonthlySummary(forSiteData: try citypage("citypage-winnipeg-en.xml"), year: 2026, month: 10, strategy: .networkOnly, loader: loader)
            }
        }
    }

    @Test func aYearWithNoStationThrowsAClearError() async throws {
        try await withCacheDirectory { directory in
            let loader = makeLoader(try transport(), cacheDirectory: directory)

            await #expect(throws: ClimateError.noClimateStation(siteName: "Edmonton", year: 1990)) {
                try await ClimateRepository.fetchMonthlySummary(forSiteData: try citypage("citypage-edmonton-en.xml"), year: 1990, month: 1, strategy: .networkOnly, loader: loader)
            }
        }
    }

    /// The year's file grows daily, so the strategy applies to it; the station list and normals are only fetched when not on disk.
    @Test func theStrategyAppliesToTheDailyFileOnly() async throws {
        try await withCacheDirectory { directory in
            let transport = try transport()
            let loader = makeLoader(transport, cacheDirectory: directory)
            let winnipeg = try citypage("citypage-winnipeg-en.xml")

            _ = try await ClimateRepository.fetchMonthlySummary(forSiteData: winnipeg, year: 2026, month: 10, strategy: .networkOnly, loader: loader)
            _ = try await ClimateRepository.fetchMonthlySummary(forSiteData: winnipeg, year: 2026, month: 10, strategy: .networkOnly, loader: loader)

            let requested = transport.requests.map(\.absoluteString)
            #expect(requested.filter { $0 == Self.dailyURL }.count == 2)
            #expect(requested.filter { $0 == Self.listURL }.count == 1)
            #expect(requested.filter { $0 == Self.richardsonNormalsURL }.count == 1)
        }
    }

    @Test func everythingCanComeFromDisk() async throws {
        try await withCacheDirectory { directory in
            let transport = try transport()
            let loader = makeLoader(transport, cacheDirectory: directory)
            let winnipeg = try citypage("citypage-winnipeg-en.xml")

            _ = try await ClimateRepository.fetchMonthlySummary(forSiteData: winnipeg, year: 2026, month: 10, strategy: .diskWithNetworkFallback, loader: loader)
            transport.stubEverythingElse(status: 500)
            let again = try await ClimateRepository.fetchMonthlySummary(forSiteData: winnipeg, year: 2026, month: 10, strategy: .diskOnly, loader: loader)

            #expect(again.normals?.averageHigh == 10.5)
        }
    }

    @Test func cancelledFetchesStopBeforeStarting() async throws {
        try await withCacheDirectory { directory in
            let transport = try transport()
            let loader = makeLoader(transport, cacheDirectory: directory)
            let winnipeg = try citypage("citypage-winnipeg-en.xml")

            let task = Task {
                withUnsafeCurrentTask { $0?.cancel() }
                return try await ClimateRepository.fetchMonthlySummary(forSiteData: winnipeg, year: 2026, month: 10, strategy: .networkOnly, loader: loader)
            }

            await #expect(throws: CancellationError.self) { try await task.value }
            #expect(transport.requests.isEmpty)
        }
    }
}
