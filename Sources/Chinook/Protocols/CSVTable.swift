//
//  CSVTable.swift
//  Chinook
//
//  Created by Gary Kash on 2026-11-05.
//

import Foundation

/// A CSV file as Datamart serves it: the first row names the columns and every other row is read by column name.
///
/// Datamart's files quote every field, end data rows with a stray comma, and (for the older observation
/// files) aren't always UTF-8. None of that should reach a model, so it's handled here.
struct CSVTable: Sendable {
    let rows: [Row]

    struct Row: Sendable {
        fileprivate let columns: [String: Int]
        fileprivate let values: [String]

        /// The trimmed value in `column`, or nil when the column is missing or the field is blank.
        subscript(column: String) -> String? {
            guard let index = columns[column], index < values.count else { return nil }

            let value = values[index].trimmingCharacters(in: .whitespaces)
            return value.isEmpty ? nil : value
        }
    }

    init(data: Data) {
        let parsed = CSVTable.records(in: data)

        guard let header = parsed.first else {
            rows = []
            return
        }

        var columns: [String: Int] = [:]
        for (index, name) in header.enumerated() where columns[name] == nil {
            columns[name] = index
        }

        rows = parsed.dropFirst().map { Row(columns: columns, values: $0) }
    }

    /// The fields of every non-blank line, for files that aren't one table: climate normals stack several, each under its own heading.
    static func records(in data: Data) -> [[String]] {
        let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) ?? ""

        return parse(text)
    }

    /// Splits `text` into records of fields: quoted fields may hold commas, line breaks and `""`.
    /// Blank lines are skipped.
    private static func parse(_ text: String) -> [[String]] {
        let characters = Array(text.drop(while: { $0 == "\u{FEFF}" }))

        var records: [[String]] = []
        var record: [String] = []
        var field = ""
        var inQuotes = false
        var index = 0

        while index < characters.count {
            let character = characters[index]

            if inQuotes {
                if character == "\"" {
                    if index + 1 < characters.count, characters[index + 1] == "\"" {
                        field.append("\"")
                        index += 1
                    }
                    else {
                        inQuotes = false
                    }
                }
                else {
                    field.append(character)
                }
            }
            else {
                switch character {
                case "\"":
                    inQuotes = true
                case ",":
                    record.append(field)
                    field = ""
                case "\n", "\r", "\r\n":
                    record.append(field)
                    field = ""

                    if !(record.count == 1 && record[0].isEmpty) {
                        records.append(record)
                    }

                    record = []
                default:
                    field.append(character)
                }
            }

            index += 1
        }

        // The last line may have no line break after it.
        if !field.isEmpty || !record.isEmpty {
            record.append(field)
            records.append(record)
        }

        return records
    }
}
