import Foundation
import Testing
@testable import Chinook

private struct Strict: XMLDecodable {
    let number: Int
}

private struct Snake: XMLDecodable {
    let firstName: String
}

@Suite struct XMLDecodableTests {
    private func failure(_ data: Data) -> String? {
        do {
            _ = try Strict.decode(fromXML: data)
            return nil
        }
        catch {
            let nsError = error as NSError
            #expect(nsError.domain == "XMLDecodableError")
            return nsError.localizedDescription
        }
    }

    @Test func aMissingKeyIsReportedWithContextAndASnippet() {
        let message = failure(Data("<strict><other>1</other></strict>".utf8))

        #expect(message?.contains("Failed to decode XML") == true)
        #expect(message?.contains("number") == true)
        #expect(message?.contains("XML Snippet") == true)
    }

    @Test func aTypeMismatchIsReported() {
        #expect(failure(Data("<strict><number>abc</number></strict>".utf8))?.contains("Failed to decode XML") == true)
    }

    @Test func anEmptyValueIsReported() {
        #expect(failure(Data("<strict><number/></strict>".utf8)) != nil)
    }

    @Test func malformedXMLIsReported() {
        #expect(failure(Data("<strict><number>1</strict>".utf8))?.contains("Failed to decode XML") == true)
    }

    @Test func bytesThatAreNotTextAreReportedWithoutASnippet() {
        let message = failure(Data([0xFF, 0xFE, 0xFD]))

        #expect(message?.contains("Unable to decode XML to string.") == true)
    }

    @Test func aKeyStrategyCanBePassedThrough() throws {
        let decoded = try Snake.decode(fromXML: Data("<snake><first_name>Ada</first_name></snake>".utf8), keyDecodingStrategy: .convertFromSnakeCase)

        #expect(decoded.firstName == "Ada")
    }
}
