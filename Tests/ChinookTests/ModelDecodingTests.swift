import Foundation
import Testing
@testable import Chinook

@Suite struct ModelDecodingTests {
    // MARK: - Live city pages

    @Test func edmontonDecodesDespiteMissingCondition() throws {
        let siteData = try SiteData.decode(fromXML: fixture("citypage-edmonton-en.xml"))

        #expect(siteData.location.name.value == "Edmonton")
        #expect(siteData.location.province == "Alberta")

        let conditions = try #require(siteData.currentConditions)
        #expect(conditions.station.code == "xec")
        #expect(conditions.visibility == nil)
        #expect(conditions.temperature.value == "9.1")
        #expect(conditions.pressure.tendency == "rising")
        #expect(conditions.pressure.value == 101.1)
        #expect(conditions.wind.speed.value == "13")
        #expect(conditions.wind.direction?.value == "WNW")

        let forecasts = try #require(siteData.forecastGroup?.forecast)
        #expect(forecasts.count >= 6)
    }

    @Test func winnipegDecodesWithAFullObservation() throws {
        let siteData = try SiteData.decode(fromXML: fixture("citypage-winnipeg-en.xml"))

        let conditions = try #require(siteData.currentConditions)
        #expect(siteData.location.name.value == "Winnipeg")
        #expect(conditions.visibility?.value != nil)
        #expect(conditions.condition?.isEmpty == false)
    }

    @Test func aStationThatIsNotReportingDecodesWithoutConditions() throws {
        let siteData = try SiteData.decode(fromXML: fixture("citypage-valemount-no-observation.xml"))

        #expect(siteData.location.name.value == "Valemount")
        #expect(siteData.currentConditions == nil)
        #expect(siteData.forecastGroup?.forecast?.isEmpty == false)
    }

    @Test func frenchPagesDecode() throws {
        let siteData = try SiteData.decode(fromXML: fixture("citypage-edmonton-fr.xml"))

        #expect(siteData.location.name.value == "Edmonton")
        #expect(siteData.forecastGroup?.forecast?.first?.textSummary?.isEmpty == false)
    }

    // MARK: - Lenient decoding policy

    private struct Probe: XMLDecodable {
        let number: Int

        enum CodingKeys: String, CodingKey { case number }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            number = container.decodeLenient(Int.self, forKey: .number, fallback: -1)
        }
    }

    private func probe(_ xml: String) throws -> Probe {
        try Probe.decode(fromXML: Data(xml.utf8))
    }

    @Test func lenientDecodingKeepsAGoodValue() throws {
        #expect(try probe("<probe><number>7</number></probe>").number == 7)
    }

    @Test func lenientDecodingFallsBackWhenTheFieldIsMissing() throws {
        #expect(try probe("<probe><other>1</other></probe>").number == -1)
    }

    @Test func lenientDecodingFallsBackWhenTheFieldIsUnusable() throws {
        #expect(try probe("<probe><number>abc</number></probe>").number == -1)
    }

    // MARK: - Fields EC leaves out

    private func decode<T: XMLDecodable>(_ type: T.Type, _ xml: String) throws -> T {
        try T.decode(fromXML: Data(xml.utf8))
    }

    @Test func pressureWithoutItsAttributesDecodes() throws {
        let pressure = try decode(Pressure.self, "<pressure>101.2</pressure>")

        #expect(pressure.value == 101.2)
        #expect(pressure.change == "")
        #expect(pressure.units == "")
        #expect(pressure.tendency == nil)
    }

    @Test func precipTypeWithoutStartAndEndDecodes() throws {
        let precipType = try decode(PrecipType.self, "<precipType/>")

        #expect(precipType.start == "")
        #expect(precipType.end == "")
    }

    @Test func precipTypeKeepsItsTimes() throws {
        let precipType = try decode(PrecipType.self, #"<precipType start="12" end="18">snow</precipType>"#)

        #expect(precipType.start == "12")
        #expect(precipType.end == "18")
    }

    @Test func windWithOnlyADirectionDecodes() throws {
        let wind = try decode(Wind.self, "<wind><direction>SW</direction></wind>")

        #expect(wind.direction?.value == "SW")
        #expect(wind.speed.value == nil)
        #expect(wind.gust.value == nil)
        #expect(wind.bearing.value == nil)
    }

    @Test func windKeepsItsMeasurements() throws {
        let wind = try decode(Wind.self, """
        <wind index="1" rank="major">
          <speed unitType="metric" units="km/h">15</speed>
          <gust unitType="metric" units="km/h">30</gust>
          <direction>SE</direction>
          <bearing units="degrees">140</bearing>
        </wind>
        """)

        #expect(wind.index == 1)
        #expect(wind.rank == "major")
        #expect(wind.speed.value == "15")
        #expect(wind.gust.value == "30")
        #expect(wind.bearing.value == "140")
    }
}
