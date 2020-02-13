//
//  NSLocale+i18n.swift
//  Chinook
//
//  Created by Gary Kash on 2020-02-02.
//  Copyright © 2020 Gary Kash. All rights reserved.
//

import Foundation

extension NSLocale {
    static var isFrench: Bool {
        guard let currentLanguageCode = NSLocale.current.languageCode else { return false } // Fall-back to English
        return currentLanguageCode.starts(with: "fr")
    }
}
