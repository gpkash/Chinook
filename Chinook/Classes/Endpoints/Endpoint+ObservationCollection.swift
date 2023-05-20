//
//  Endpoint+Yesterday.swift
//  Retro Weather
//
//  Created by Gary Kash on 2020-03-21.
//

import Foundation

extension Endpoint {
    static var timestamp: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        return dateFormatter.string(from: Date())
    }
    
    public static func observationCollection(forProvinceWithCode provinceCode: String) -> Endpoint {
        let languageComponent = NSLocale.language == .french ? "f" : "e"
        let path = "/observations/xml/\(provinceCode.uppercased())/yesterday/yesterday_\(provinceCode.lowercased())_\(timestamp)_\(languageComponent).xml"
        return Endpoint(host: .datamart, path: path)
    }
}
