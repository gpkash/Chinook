//
//  NSLocale+i18n.swift
//  Chinook
//
//  Created by Gary Kash on 2020-02-02.
//  Copyright © 2020 Gary Kash. All rights reserved.
//

import Foundation

public extension NSLocale {
    static var language: Language {
        for languageCode in NSLocale.preferredLanguages {
            if languageCode.starts(with: "fr") {
                return .french
            }
            else if languageCode.starts(with: "en") {
                return .english
            }
        }
        
        return .english
    }
}
