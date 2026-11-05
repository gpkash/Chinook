import Foundation
import Testing
@testable import Chinook

private func siteXML(currentConditions: String) -> Data {
    Data("""
    <?xml version="1.0" encoding="UTF-8"?>
    <siteData>
       <dateTime name="xmlCreation" zone="UTC" UTCOffset="0">
          <year>2026</year><month name="November">11</month><day name="Thursday">05</day>
          <hour>19</hour><minute>01</minute><timeStamp>20261105190100</timeStamp>
          <textSummary>Thursday November 05, 2026 at 19:01 UTC</textSummary>
       </dateTime>
       <location>
          <continent>North America</continent>
          <country code="ca">Canada</country>
          <province code="ab">Alberta</province>
          <name code="s0000045" lat="53.54N" lon="113.49W">Edmonton</name>
          <region>City of Edmonton - St. Albert - Sherwood Park</region>
       </location>
       \(currentConditions)
    </siteData>
    """.utf8)
}

@Test func decodesLocationName() throws {
    let siteData = try SiteData.decode(fromXML: siteXML(currentConditions: ""))
    #expect(siteData.location.name.value == "Edmonton")
    #expect(siteData.location.name.lat == "53.54N")
}

/// A station that isn't reporting is published as an empty `<currentConditions/>`.
@Test func emptyCurrentConditionsDecodesAsNil() throws {
    let siteData = try SiteData.decode(fromXML: siteXML(currentConditions: "<currentConditions/>"))
    #expect(siteData.currentConditions == nil)
}

/// Edmonton Blatchford reports no condition, icon or visibility.
@Test func currentConditionsWithoutConditionIconOrVisibilityDecodes() throws {
    let siteData = try SiteData.decode(fromXML: siteXML(currentConditions: """
    <currentConditions>
       <station code="xec" lat="53.59N" lon="113.51W">Edmonton Blatchford</station>
       <condition></condition>
       <iconCode format="gif"/>
       <temperature unitType="metric" units="C" qaValue="100">9.1</temperature>
       <dewpoint unitType="metric" units="C">0.1</dewpoint>
       <pressure unitType="metric" units="kPa" change="0.02" tendency="rising">101.1</pressure>
       <relativeHumidity units="%" qaValue="100">53</relativeHumidity>
       <wind>
          <speed unitType="metric" units="km/h" qaValue="100">13</speed>
          <gust unitType="metric" units="km/h"></gust>
          <direction qaValue="100">WNW</direction>
          <bearing units="degrees" qaValue="100">300.2</bearing>
       </wind>
    </currentConditions>
    """))
    let conditions = try #require(siteData.currentConditions)
    #expect(conditions.visibility == nil)
    #expect(conditions.temperature.value == "9.1")
}
