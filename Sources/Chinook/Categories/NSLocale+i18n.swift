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
        Language.preferred(from: NSLocale.preferredLanguages)
    }
}
