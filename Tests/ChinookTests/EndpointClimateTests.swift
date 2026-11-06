import Foundation
import Testing
@testable import Chinook

@Suite struct EndpointClimateTests {
    private func urlString(_ endpoint: Endpoint) -> String? {
        endpoint.url?.absoluteString
    }

    @Test func dailyObservationsAreOneFilePerStationAndYear() {
        let endpoint = Endpoint.climateDaily(province: .manitoba, climateID: "5023227", year: 2025)

        #expect(urlString(endpoint) == "https://dd.weather.gc.ca/today/climate/observations/daily/csv/MB/climate_daily_MB_5023227_2025_P1D.csv")
    }

    @Test func normalsAre1981To2010() {
        let endpoint = Endpoint.climateNormals(province: .manitoba, climateID: "5023222")

        #expect(urlString(endpoint) == "https://dd.weather.gc.ca/today/climate/observations/normals/csv/1981-2010/MB/climate_normals_MB_5023222_1981-2010.csv")
    }

    @Test func recordsAreOneFilePerVirtualStation() {
        let endpoint = Endpoint.climateRecords(province: .manitoba, virtualClimateID: "VSMB38V")

        #expect(urlString(endpoint) == "https://dd.weather.gc.ca/today/climate/ltce/daily/temperature/MB/climate_LTCE_Temperature-Records_MB_VSMB38V.csv")
    }

    @Test func stationListFollowsTheLanguage() {
        #expect(urlString(.climateStationList(language: .english)) == "https://dd.weather.gc.ca/today/climate/observations/climate_station_list.csv")
        #expect(urlString(.climateStationList(language: .french)) == "https://dd.weather.gc.ca/today/climate/observations/climate_station_list_fre.csv")
    }

    @Test func recordStationsEndpoint() {
        #expect(urlString(.climateRecordStations) == "https://dd.weather.gc.ca/today/climate/ltce/stations/climate_LTCE_Temperature_Virtual-Stations.csv")
    }

    /// Province codes elsewhere in Chinook are lowercase (`Site.provinceCode`); Datamart's directories are uppercase.
    @Test func provinceCodeIsUppercasedInPaths() {
        let province = Province(abbreviation: "mb", nameEn: "Manitoba", nameFr: "Manitoba")

        #expect(Endpoint.climateDaily(province: province, climateID: "5023227", year: 2025).path.contains("/MB/climate_daily_MB_"))
        #expect(Endpoint.climateNormals(province: province, climateID: "5023222").path.contains("/MB/climate_normals_MB_"))
        #expect(Endpoint.climateRecords(province: province, virtualClimateID: "VSMB38V").path.contains("/MB/climate_LTCE_Temperature-Records_MB_"))
    }

    @Test func everyProvinceGetsItsOwnDirectory() {
        let paths = Set(Province.lookupTable.values.map {
            Endpoint.climateDaily(province: $0, climateID: "1", year: 2025).path
        })

        #expect(paths.count == Province.count)
    }

    /// The loader caches by path, so two different files must never share one.
    @Test func differentFilesNeverShareACachePath() {
        let endpoints = [
            Endpoint.climateDaily(province: .manitoba, climateID: "5023227", year: 2025),
            Endpoint.climateDaily(province: .manitoba, climateID: "5023227", year: 2024),
            Endpoint.climateNormals(province: .manitoba, climateID: "5023227"),
            Endpoint.climateRecords(province: .manitoba, virtualClimateID: "VSMB38V"),
            Endpoint.climateRecordStations,
            Endpoint.climateStationList(language: .english),
            Endpoint.climateStationList(language: .french)
        ]

        #expect(Set(endpoints.map(\.cacheRelativePath)).count == endpoints.count)
    }
}
