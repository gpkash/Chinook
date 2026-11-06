//
//  SiteData+CGPoint.swift
//  Chinook
//
//  Created by Gary Kash on 2020-12-21.
//

import Foundation

extension SiteData {
    /// Where the site is.
    var point: CGPoint? {
        CGPoint(ecLatitude: location.name.lat, longitude: location.name.lon)
    }

    /// Where the station that measured the current conditions is, or nil if none is reporting.
    var observationPoint: CGPoint? {
        guard let station = currentConditions?.station else { return nil }

        return CGPoint(ecLatitude: station.lat, longitude: station.lon)
    }
}

extension CGPoint {
    /// From EC's coordinate strings, e.g. `"49.91N"` and `"97.24W"`.
    init?(ecLatitude latitudeText: String, longitude longitudeText: String) {
        let latitudeString = latitudeText.uppercased()
            .replacingOccurrences(of: "N", with: "")
            .replacingOccurrences(of: "S", with: "")

        let longitudeString = longitudeText.uppercased()
            .replacingOccurrences(of: "E", with: "")
            .replacingOccurrences(of: "W", with: "")

        guard var latitude = Double(latitudeString), var longitude = Double(longitudeString) else { return nil }

        if latitudeText.uppercased().contains("S") {
            latitude = -latitude
        }

        if longitudeText.uppercased().contains("W") {
            longitude = -longitude
        }

        self.init(latitude: latitude, longitude: longitude)
    }
}

extension CGPoint {
    /// Map convention used everywhere in Chinook: x is longitude, y is latitude.
    init(latitude: Double, longitude: Double) {
        self.init(x: longitude, y: latitude)
    }
}
