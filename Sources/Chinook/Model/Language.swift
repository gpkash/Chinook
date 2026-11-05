//
//  Language.swift
//  Chinook
//
//  Created by Gary Kash on 2020-12-26.
//

import Foundation

public enum Language: String {
    case english = "en-CA"
    case french = "fr-CA"
}

public extension Language {
    /// The first of `codes` (preferred languages, best first) that Chinook supports, or English.
    static func preferred(from codes: [String]) -> Language {
        for code in codes {
            if code.starts(with: "fr") {
                return .french
            }
            else if code.starts(with: "en") {
                return .english
            }
        }

        return .english
    }

    /// Picks between an English and a French string. The one place that decides which to use.
    func pick(en: String, fr: String) -> String {
        self == .french ? fr : en
    }
}
