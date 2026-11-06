import Foundation
import Testing
@testable import Chinook

private let winnipeg = Site(code: "s0000193", nameEn: "Winnipeg", nameFr: "Winnipeg", provinceCode: "MB")
private let edmonton = Site(code: "s0000045", nameEn: "Edmonton", nameFr: "Edmonton", provinceCode: "AB")
private let charlottetown = Site(code: "s0000330", nameEn: "Charlottetown", nameFr: "Charlottetown", provinceCode: "pe")
private let zeballos = Site(code: "s0000901", nameEn: "Zeballos", nameFr: "Zeballos", provinceCode: "BC")

private let base = "https://dd.weather.gc.ca/today/climate/ltce"

private func ecTransport() throws -> FakeTransport {
    let transport = FakeTransport()
    transport.stub("\(base)/stations/climate_LTCE_Temperature_Virtual-Stations.csv", body: try fixtureString("ltce-stations.csv"))
    transport.stub("\(base)/daily/temperature/MB/climate_LTCE_Temperature-Records_MB_VSMB38V.csv", body: try fixtureString("ltce-records-winnipeg.csv"))
    return transport
}

private func stations() throws -> ClimateRecordStations {
    ClimateRecordStations(csv: try fixture("ltce-stations.csv"))
}

@Suite struct ClimateRecordStationsTests {
    @Test func eachStationIsListedOnceHoweverManyObservingStationsBuildIt() throws {
        let list = try stations()

        #expect(list.stations.map(\.virtualClimateID) == ["VSAB22V", "VSAB50V", "VSMB38V", "VSPE5VV"])
    }

    @Test func aSiteIsMatchedByProvinceAndName() throws {
        let list = try stations()

        #expect(list.station(for: winnipeg)?.virtualClimateID == "VSMB38V")
        #expect(list.station(for: edmonton)?.virtualClimateID == "VSAB50V")
        #expect(list.station(for: winnipeg)?.cityCode == "MB-38")
    }

    @Test func provinceCodeCaseDoesNotMatter() throws {
        #expect(try stations().station(for: charlottetown)?.virtualClimateID == "VSPE5VV")
    }

    @Test func theProvinceMustMatchToo() throws {
        let winnipegBeach = Site(code: "s0", nameEn: "Winnipeg", nameFr: "Winnipeg", provinceCode: "ON")

        #expect(try stations().station(for: winnipegBeach) == nil)
    }

    @Test func aSiteWithoutRecordsHasNoStation() throws {
        #expect(try stations().station(for: zeballos) == nil)
    }

    @Test func accentsPunctuationAndTheWordAreaDoNotCount() {
        #expect(ClimateRecordStations.key(province: "QC", name: "Saint-Rémi") == ClimateRecordStations.key(province: "QC", name: "SAINT REMI AREA"))
        #expect(ClimateRecordStations.key(province: "QC", name: "Québec") == ClimateRecordStations.key(province: "QC", name: "QUEBEC"))
    }

    @Test func aPlaceCalledAreaKeepsItsName() {
        #expect(ClimateRecordStations.key(province: "ON", name: "Area") == "ON|AREA")
    }

    @Test func aCityWithTwoSeriesGivesThePlainNameToTheAirport() {
        let csv = """
        "LONGITUDE","LATITUDE","PROVINCE_CODE","VIRTUAL_CLIMATE_ID","VIRTUAL_STATION_NAME_E","VIRTUAL_STATION_NAME_F","WXO_CITY_CODE"
        "-63.5","44.88","NS","VSNS19V","HALIFAX (AIRPORT) AREA","HALIFAX (AÉROPORT)","NS-19",
        "-63.5","44.63","NS","VSNS40V","HALIFAX (SHEARWATER) AREA","HALIFAX (SHEARWATER)","NS-40",
        """
        let list = ClimateRecordStations(csv: Data(csv.utf8))
        let halifax = Site(code: "s0000318", nameEn: "Halifax", nameFr: "Halifax", provinceCode: "NS")
        let shearwater = Site(code: "s0000084", nameEn: "Halifax (Shearwater)", nameFr: "Halifax (Shearwater)", provinceCode: "NS")

        #expect(list.station(for: halifax)?.virtualClimateID == "VSNS19V")
        #expect(list.station(for: shearwater)?.virtualClimateID == "VSNS40V")
    }

    @Test func theFrenchNameIsTriedWhenTheEnglishOneIsNotListed() throws {
        let csv = """
        "LONGITUDE","LATITUDE","PROVINCE_CODE","VIRTUAL_CLIMATE_ID","VIRTUAL_STATION_NAME_E","VIRTUAL_STATION_NAME_F","WXO_CITY_CODE"
        "-71.2","46.8","QC","VSQC133","QUEBEC CITY AREA","QUÉBEC","QC-133",
        """
        let list = ClimateRecordStations(csv: Data(csv.utf8))
        let site = Site(code: "s1", nameEn: "Quebec", nameFr: "Québec", provinceCode: "QC")

        #expect(list.station(for: site)?.virtualClimateID == "VSQC133")
    }
}

@Suite struct TemperatureRecordsTests {
    private func winnipegRecords() throws -> TemperatureRecords {
        let station = try #require(try stations().station(for: winnipeg))
        return TemperatureRecords(csv: try fixture("ltce-records-winnipeg.csv"), station: station)
    }

    @Test func everyDayInTheFileIsRead() throws {
        #expect(try winnipegRecords().days.map { [$0.month, $0.day] } == [[1, 1], [1, 2], [1, 3], [2, 29]])
    }

    @Test func aDayHoldsTheFourRecordsAndTheirYears() throws {
        let day = try #require(try winnipegRecords().records(month: 1, day: 2))

        #expect(day.recordHigh == TemperatureRecord(temperature: 3.3, year: 1889))
        #expect(day.coldestHigh == TemperatureRecord(temperature: -28.3, year: 1888))
        #expect(day.warmestLow == TemperatureRecord(temperature: -2.8, year: 1964))
        #expect(day.recordLow == TemperatureRecord(temperature: -40.6, year: 1885))
    }

    @Test func aDayIsFoundByDate() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = try #require(calendar.date(from: DateComponents(year: 2026, month: 1, day: 3)))

        #expect(try winnipegRecords().records(on: date, calendar: calendar)?.day == 3)
    }

    @Test func aDayEcDoesNotListIsNil() throws {
        #expect(try winnipegRecords().records(month: 7, day: 4) == nil)
    }

    @Test func aMissingRecordIsNilWithoutLosingTheDay() {
        let csv = """
        "LOCAL_MONTH","LOCAL_DAY","RECORD_HIGH_MAX_TEMP","RECORD_HIGH_MAX_TEMP_YR","RECORD_LOW_MIN_TEMP","RECORD_LOW_MIN_TEMP_YR"
        "6","1","31.5","1990","","",
        """
        let station = ClimateRecordStation(virtualClimateID: "VSXX1VV", province: .manitoba, cityCode: "MB-1", nameEn: "X", nameFr: "X")
        let day = TemperatureRecords(csv: Data(csv.utf8), station: station).records(month: 6, day: 1)

        #expect(day?.recordHigh == TemperatureRecord(temperature: 31.5, year: 1990))
        #expect(day?.recordLow == nil)
        #expect(day?.coldestHigh == nil)
    }
}

@Suite struct ClimateRepositoryTests {
    @Test func anySiteGetsItsOwnCitysRecords() async throws {
        try await withCacheDirectory { directory in
            let transport = try ecTransport()
            transport.stub("\(base)/daily/temperature/AB/climate_LTCE_Temperature-Records_AB_VSAB50V.csv", body: try fixtureString("ltce-records-winnipeg.csv"))
            let loader = makeLoader(transport, cacheDirectory: directory)

            let winnipegRecords = try await ClimateRepository.fetchTemperatureRecords(forSite: winnipeg, strategy: .networkOnly, loader: loader)
            let edmontonRecords = try await ClimateRepository.fetchTemperatureRecords(forSite: edmonton, strategy: .networkOnly, loader: loader)

            #expect(winnipegRecords.station.virtualClimateID == "VSMB38V")
            #expect(edmontonRecords.station.virtualClimateID == "VSAB50V")
            #expect(transport.requests.map(\.lastPathComponent).contains("climate_LTCE_Temperature-Records_AB_VSAB50V.csv"))
        }
    }

    @Test func aSiteWithoutRecordsThrowsAClearError() async throws {
        try await withCacheDirectory { directory in
            let loader = makeLoader(try ecTransport(), cacheDirectory: directory)

            await #expect(throws: ClimateError.noRecordStation(siteCode: "s0000901")) {
                try await ClimateRepository.fetchTemperatureRecords(forSite: zeballos, strategy: .networkOnly, loader: loader)
            }
        }
    }

    @Test func theStationListIsKeptOnDiskForNextTime() async throws {
        try await withCacheDirectory { directory in
            let transport = try ecTransport()
            let loader = makeLoader(transport, cacheDirectory: directory)

            _ = try await ClimateRepository.fetchTemperatureRecords(forSite: winnipeg, strategy: .diskWithNetworkFallback, loader: loader)
            transport.stubEverythingElse(status: 500)
            let again = try await ClimateRepository.fetchTemperatureRecords(forSite: winnipeg, strategy: .diskOnly, loader: loader)

            #expect(again.station.virtualClimateID == "VSMB38V")
        }
    }

    @Test func aServerErrorOnTheRecordsFileIsReported() async throws {
        try await withCacheDirectory { directory in
            let transport = try ecTransport()
            transport.stub("\(base)/daily/temperature/MB/climate_LTCE_Temperature-Records_MB_VSMB38V.csv", status: 404)
            let loader = makeLoader(transport, cacheDirectory: directory)

            await #expect(throws: NetworkError.self) {
                try await ClimateRepository.fetchTemperatureRecords(forSite: winnipeg, strategy: .networkOnly, loader: loader)
            }
        }
    }

    @Test func cancelledFetchesStopBeforeStarting() async throws {
        try await withCacheDirectory { directory in
            let transport = try ecTransport()
            let loader = makeLoader(transport, cacheDirectory: directory)

            let task = Task {
                withUnsafeCurrentTask { $0?.cancel() }
                return try await ClimateRepository.fetchTemperatureRecords(forSite: winnipeg, strategy: .networkOnly, loader: loader)
            }

            await #expect(throws: CancellationError.self) { try await task.value }
            #expect(transport.requests.isEmpty)
        }
    }
}
