//
//  SiteData+CGPoint.swift
//  Chinook
//
//  Created by Gary Kash on 2020-12-21.
//

import Foundation

extension SiteData {
    var point: CGPoint? {
        let latitudeString = location.name.lat.uppercased()
            .replacingOccurrences(of: "N", with: "")
            .replacingOccurrences(of: "S", with: "")

        let longitudeString = location.name.lon.uppercased()
            .replacingOccurrences(of: "E", with: "")
            .replacingOccurrences(of: "W", with: "")

        guard var latitude = Double(latitudeString), var longitude = Double(longitudeString) else { return nil }
        
        if location.name.lat.uppercased().contains("S") {
            latitude = -latitude
        }

        if location.name.lon.uppercased().contains("W") {
            longitude = -longitude
        }

        return CGPoint(x: longitude, y: latitude)
    }
}
