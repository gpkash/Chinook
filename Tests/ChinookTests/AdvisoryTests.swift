import CoreGraphics
import Foundation
import Testing
@testable import Chinook

private func alert(_ name: String) throws -> Alert {
    try Alert.decode(fromXML: fixture(name))
}

// Fort Simpson is inside the freezing rain polygons; Yellowknife is not.
private let fortSimpson = (latitude: "61.87N", longitude: "121.35W")
private let yellowknife = (latitude: "62.45N", longitude: "114.37W")

@Suite struct AdvisoryTests {
    // MARK: - Grouping

    @Test func updatesToTheSameAlertGroupIntoOneAdvisory() throws {
        let alerts = try ["alert-freezing-rain-1.cap", "alert-freezing-rain-2.cap", "alert-freezing-rain-3.cap"].map(alert)

        let advisories = Advisory.advisories(from: alerts, language: .english, now: utc(hour: 21))

        #expect(advisories.count == 1)
        let advisory = try #require(advisories.first)
        #expect(!advisory.designationCode.isEmpty)
        #expect(advisory.urgency == "Immediate")
        #expect(!advisory.areas.isEmpty)
        #expect(advisory.shortDescription == advisory.description.components(separatedBy: "\n\n###\n\n")[0])
    }

    @Test func differentAlertsBecomeSeparateAdvisoriesInStableOrder() throws {
        let alerts = try ["alert-wind-chilcotin.cap", "alert-freezing-rain-3.cap"].map(alert)

        let first = Advisory.advisories(from: alerts, language: .english, now: utc(hour: 21))
        let second = Advisory.advisories(from: alerts.reversed(), language: .english, now: utc(hour: 21))

        #expect(first.count == 2)
        #expect(first.map(\.designationCode) == first.map(\.designationCode).sorted())
        #expect(first.map(\.designationCode) == second.map(\.designationCode))
    }

    @Test func advisoriesFollowTheRequestedLanguage() throws {
        let alerts = [try alert("alert-freezing-rain-3.cap")]

        let english = try #require(Advisory.advisories(from: alerts, language: .english, now: utc(hour: 21)).first)
        let french = try #require(Advisory.advisories(from: alerts, language: .french, now: utc(hour: 21)).first)

        #expect(english.description != french.description)
        #expect(english.areas.first?.areaDesc != french.areas.first?.areaDesc)
    }

    @Test func noAlertsMakeNoAdvisories() {
        #expect(Advisory.advisories(from: [], language: .english).isEmpty)
    }

    @Test func infosAreOrderedByCapCount() throws {
        let alerts = try ["alert-freezing-rain-3.cap", "alert-freezing-rain-1.cap", "alert-freezing-rain-2.cap"].map(alert)

        let counts = alerts.alertInfos(forLanguage: .english).map(\.capCount)

        #expect(counts == counts.sorted())
        #expect(counts.count == 3)
    }

    // MARK: - Time is a seam

    @Test func whenTheNewestUpdateExpiresTheAdvisoryFallsBackToTheOlderOne() throws {
        let alerts = try ["alert-freezing-rain-1.cap", "alert-freezing-rain-2.cap", "alert-freezing-rain-3.cap"].map(alert)
        let secondExpiry = try #require(alerts[1].info.first { $0.language == "en-CA" }?.expiresDate)

        // The newest update expires at 01:00 on the 6th; the older two run until nearly 06:00.
        let during = try #require(Advisory.advisories(from: alerts, language: .english, now: utc(hour: 21)).first)
        let after = try #require(Advisory.advisories(from: alerts, language: .english, now: utc(hour: 2, day: 6)).first)

        #expect(during.expires == utc(hour: 1, day: 6).addingTimeInterval(53))
        #expect(after.expires == secondExpiry)
    }

    @Test func anAlertIsActiveBetweenItsEffectiveAndExpiryTimes() throws {
        let info = try #require(try alert("alert-freezing-rain-3.cap").info.first { $0.language == "en-CA" })

        #expect(info.effectiveDate == utc(hour: 20, minute: 19).addingTimeInterval(53))
        #expect(info.expiresDate == utc(hour: 1, minute: 0, day: 6).addingTimeInterval(53))
        #expect(!info.isActive(at: utc(hour: 20, minute: 19)))
        #expect(info.isActive(at: utc(hour: 21)))
        #expect(!info.isActive(at: utc(hour: 2, day: 6)))
        #expect(info.isExpired(at: utc(hour: 2, day: 6)))
        #expect(!info.isExpired(at: utc(hour: 21)))
        #expect(info.isInEffect(at: utc(hour: 21)))
    }

    @Test func allClearAndPastAlertsAreNotInEffect() throws {
        let xml = try fixtureString("alert-freezing-rain-3.cap")

        let allClear = try Alert.decode(fromXML: Data(xml.replacingOccurrences(of: "<responseType>Monitor", with: "<responseType>AllClear").utf8))
        let past = try Alert.decode(fromXML: Data(xml.replacingOccurrences(of: "<urgency>Immediate", with: "<urgency>Past").utf8))

        #expect(allClear.info.allSatisfy { !$0.isInEffect(at: utc(hour: 21)) })
        #expect(past.info.allSatisfy { !$0.isInEffect(at: utc(hour: 21)) })
    }

    @Test func missingTimesMeanActiveAndNotExpired() throws {
        var xml = try fixtureString("alert-freezing-rain-3.cap")
        xml = xml.replacingOccurrences(of: #"<effective>[^<]*</effective>"#, with: "", options: .regularExpression)
        xml = xml.replacingOccurrences(of: #"<expires>[^<]*</expires>"#, with: "", options: .regularExpression)
        let info = try #require(try Alert.decode(fromXML: Data(xml.utf8)).info.first)

        #expect(info.effectiveDate == nil)
        #expect(info.expiresDate == nil)
        #expect(info.isActive(at: utc(hour: 3)))
        #expect(!info.isExpired(at: utc(hour: 3)))
    }

    @Test func theNoArgumentTimeChecksUseTheCurrentTime() throws {
        let info = try #require(try alert("alert-freezing-rain-3.cap").info.first)

        #expect(info.isExpired == info.isExpired(at: Date()))
        #expect(info.isActive == info.isActive(at: Date()))
        #expect(info.isInEffect == info.isInEffect(at: Date()))
    }

    // MARK: - Alert parameters

    @Test func theDesignationCodeAndCapCountAreReadFromParameters() throws {
        let info = try #require(try alert("alert-freezing-rain-3.cap").info.first)

        #expect(info.designationCode != nil)
        #expect(info.capCount == 144960)
    }

    @Test func aMalformedOrMissingCapCountIsZero() throws {
        let xml = try fixtureString("alert-freezing-rain-3.cap")

        let malformed = try Alert.decode(fromXML: Data(xml.replacingOccurrences(of: "A:24522 M:125663 C:144960", with: "garbage").utf8))
        let notANumber = try Alert.decode(fromXML: Data(xml.replacingOccurrences(of: "A:24522 M:125663 C:144960", with: "A:1 M:2 C:x").utf8))
        let missing = try Alert.decode(fromXML: Data(xml.replacingOccurrences(of: "CAP_count", with: "Other").utf8))

        #expect(malformed.info.allSatisfy { $0.capCount == 0 })
        #expect(notANumber.info.allSatisfy { $0.capCount == 0 })
        #expect(missing.info.allSatisfy { $0.capCount == 0 })
    }

    @Test func alertsAreEqualByIdentifierAndInfosByContent() throws {
        let first = try alert("alert-freezing-rain-1.cap")
        let second = try alert("alert-freezing-rain-2.cap")

        #expect(first == (try alert("alert-freezing-rain-1.cap")))
        #expect(first != second)
        #expect(first.info.first == (try alert("alert-freezing-rain-1.cap")).info.first)
        #expect(first.info.first != second.info.first)
    }

    // MARK: - Which advisories apply to a site

    @Test func anAdvisoryAppliesToASiteInsideItsArea() throws {
        let advisories = Advisory.advisories(from: [try alert("alert-freezing-rain-3.cap")], language: .english, now: utc(hour: 21))

        let inside = try siteData(latitude: fortSimpson.latitude, longitude: fortSimpson.longitude)
        let outside = try siteData(latitude: yellowknife.latitude, longitude: yellowknife.longitude)

        #expect(advisories.inEffectFor(siteData: inside).count == 1)
        #expect(advisories.inEffectFor(siteData: outside).isEmpty)
    }

    @Test func anAdvisoryMatchingSeveralAreasIsListedOnce() throws {
        // English and French infos carry one area each, so together the advisory has two areas covering the site.
        let alert = try alert("alert-freezing-rain-3.cap")
        let advisory = Advisory(designationCode: "x", alertInfos: alert.info, now: utc(hour: 21))
        let inside = try siteData(latitude: fortSimpson.latitude, longitude: fortSimpson.longitude)

        #expect(advisory.areas.count == 2)
        #expect([advisory].inEffectFor(siteData: inside).count == 1)
    }

    @Test func aSiteWithoutUsableCoordinatesMatchesNothing() throws {
        let advisories = Advisory.advisories(from: [try alert("alert-freezing-rain-3.cap")], language: .english, now: utc(hour: 21))
        let unlocated = try siteData(latitude: "unknown", longitude: "unknown")

        #expect(unlocated.point == nil)
        #expect(advisories.inEffectFor(siteData: unlocated).isEmpty)
    }

    // MARK: - Polygons and coordinates

    @Test func southernAndEasternCoordinatesAreSigned() throws {
        let point = try #require(try siteData(latitude: "45.50S", longitude: "10.20E").point)

        #expect(point == CGPoint(x: 10.2, y: -45.5))
        #expect(try #require(try siteData(latitude: "45.50N", longitude: "10.20W").point) == CGPoint(x: -10.2, y: 45.5))
    }

    @Test func theMapConventionIsLongitudeThenLatitude() {
        #expect(CGPoint(latitude: 60, longitude: -120) == CGPoint(x: -120, y: 60))
    }

    @Test func aPolygonContainsTheSiteInsideItAndNotOneOutside() throws {
        let area = try #require(try alert("alert-freezing-rain-3.cap").info.first?.area.first)
        let inside = try siteData(latitude: fortSimpson.latitude, longitude: fortSimpson.longitude)
        let outside = try siteData(latitude: yellowknife.latitude, longitude: yellowknife.longitude)

        #expect(area.inEffectFor(siteData: inside))
        #expect(!area.inEffectFor(siteData: outside))
        #expect(area.cgPath.contains(CGPoint(x: -121.0, y: 61.6)))
    }

    @Test func polygonPointsThatDoNotParseAreSkipped() {
        let area = AlertArea(areaDesc: "square", polygon: "0,0 oops 0,10 10,10 bad,point 10,0 0,0", geocode: [])

        #expect(area.cgPath.contains(CGPoint(x: 5, y: 5)))
        #expect(!area.cgPath.contains(CGPoint(x: 15, y: 5)))
    }

    @Test func anEmptyPolygonContainsNothing() {
        let area = AlertArea(areaDesc: "none", polygon: "", geocode: [])

        #expect(!area.cgPath.contains(.zero))
    }
}
