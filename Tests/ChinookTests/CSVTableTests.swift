import Foundation
import Testing
@testable import Chinook

private func table(_ text: String) -> CSVTable {
    CSVTable(data: Data(text.utf8))
}

@Suite struct CSVTableTests {
    @Test func rowsAreReadByColumnName() {
        let rows = table("\"A\",\"B\"\n\"1\",\"2\"\n\"3\",\"4\"\n").rows

        #expect(rows.map { $0["A"] } == ["1", "3"])
        #expect(rows.map { $0["B"] } == ["2", "4"])
    }

    @Test func quotedFieldsKeepCommasQuotesAndLineBreaks() {
        let row = table("\"A\",\"B\"\n\"one, two\",\"say \"\"hi\"\"\nthere\"\n").rows[0]

        #expect(row["A"] == "one, two")
        #expect(row["B"] == "say \"hi\"\nthere")
    }

    @Test func aTrailingCommaOnDataRowsDoesNotShiftColumns() {
        let rows = table("\"A\",\"B\"\n\"1\",\"2\",\n").rows

        #expect(rows.count == 1)
        #expect(rows[0]["A"] == "1")
        #expect(rows[0]["B"] == "2")
    }

    @Test func blankFieldsAndMissingColumnsAreNil() {
        let row = table("\"A\",\"B\"\n\"\",\"2\"\n").rows[0]

        #expect(row["A"] == nil)
        #expect(row["Z"] == nil)
    }

    @Test func windowsLineEndingsAndNoFinalNewlineAreAccepted() {
        let rows = table("A,B\r\n1,2\r\n3,4").rows

        #expect(rows.map { $0["B"] } == ["2", "4"])
    }

    @Test func blankLinesAreSkipped() {
        let rows = table("A\n\n1\n\n2\n").rows

        #expect(rows.map { $0["A"] } == ["1", "2"])
    }

    @Test func aByteOrderMarkDoesNotSpoilTheFirstColumnName() {
        let rows = table("\u{FEFF}\"A\",\"B\"\n\"1\",\"2\"\n").rows

        #expect(rows[0]["A"] == "1")
    }

    /// Older observation files are Latin-1: "°C" in a header must not lose the whole file.
    @Test func nonUTF8FilesAreReadAsLatin1() throws {
        let data = try #require("\"Max Temp (\u{B0}C)\"\n\"-14.5\"\n".data(using: .isoLatin1))

        #expect(CSVTable(data: data).rows[0]["Max Temp (\u{B0}C)"] == "-14.5")
    }

    @Test func anEmptyFileHasNoRows() {
        #expect(table("").rows.isEmpty)
        #expect(table("A,B\n").rows.isEmpty)
    }
}
