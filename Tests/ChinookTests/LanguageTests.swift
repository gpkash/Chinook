import Foundation
import Testing
@testable import Chinook

@Suite struct LanguageTests {
    @Test func theFirstSupportedPreferredLanguageWins() {
        #expect(Language.preferred(from: ["fr-CA", "en-CA"]) == .french)
        #expect(Language.preferred(from: ["de-DE", "en-US"]) == .english)
        #expect(Language.preferred(from: ["de-DE", "fr-FR"]) == .french)
        #expect(Language.preferred(from: ["en"]) == .english)
    }

    @Test func englishIsTheDefault() {
        #expect(Language.preferred(from: []) == .english)
        #expect(Language.preferred(from: ["xx", "yy"]) == .english)
    }

    @Test func theSystemLanguageIsOneOfTheSupportedOnes() {
        #expect([Language.english, .french].contains(NSLocale.language))
    }

    @Test func pickChoosesByLanguage() {
        #expect(Language.english.pick(en: "Quebec", fr: "Québec") == "Quebec")
        #expect(Language.french.pick(en: "Quebec", fr: "Québec") == "Québec")
    }

    // MARK: - Names

    @Test func sitesAndProvincesNameThemselvesInTheRequestedLanguage() {
        let site = Site(code: "s1", nameEn: "Isle-aux-Coudres", nameFr: "Île-aux-Coudres", provinceCode: "QC")

        #expect(site.name(in: .english) == "Isle-aux-Coudres")
        #expect(site.name(in: .french) == "Île-aux-Coudres")
        #expect([site.nameEn, site.nameFr].contains(site.name))
        #expect(Province.quebec.name(in: .french) == "Québec")
        #expect([Province.quebec.nameEn, Province.quebec.nameFr].contains(Province.quebec.name))
    }

    @Test func sitesAreEqualByCode() {
        let a = Site(code: "s1", nameEn: "A", nameFr: "A", provinceCode: "AB")
        let b = Site(code: "s1", nameEn: "Other", nameFr: "Autre", provinceCode: "BC")

        #expect(a == b)
        #expect(a != Site(code: "s2", nameEn: "A", nameFr: "A", provinceCode: "AB"))
    }

    // MARK: - Provinces

    @Test func princeEdwardIslandIsSpelledCorrectly() {
        #expect(Province.priceEdwardIsland.nameEn == "Prince Edward Island")
    }

    @Test func provinceCodesResolveCaseInsensitivelyIncludingAliases() {
        #expect(Province.forCode("ab") == .alberta)
        #expect(Province.forCode("PEI") == .priceEdwardIsland)
        #expect(Province.forCode("nwt") == .northwestTerritories)
        #expect(Province.forCode("ZZ") == nil)
    }

    @Test func thereAreThirteenProvincesAndTerritories() {
        #expect(Province.count == 13)
    }

    // MARK: - Site list

    @Test func sitesGroupByProvinceAndSkipUnknownOnes() throws {
        let siteList = try SiteList.decode(fromXML: fixture("sitelist.xml"))

        let grouped = siteList.sitesByProvince(in: .english)

        #expect(grouped[.alberta]?.map(\.nameEn) == ["Calgary", "Edmonton"])
        #expect(grouped[.manitoba]?.count == 1)
        #expect(grouped.values.flatMap { $0 }.count == 7)
        #expect(siteList.sitesByProvince.keys.count == grouped.keys.count)
    }

    @Test func frenchNamesSortLocaleAwareSoAccentedLettersStayWithTheirBase() throws {
        let siteList = try SiteList.decode(fromXML: fixture("sitelist.xml"))

        let quebec = try #require(siteList.sitesByProvince(in: .french)[.quebec])

        #expect(quebec.map { $0.nameFr } == ["Île-aux-Coudres", "Inukjuak", "Zeballos"])
    }
}
