//
//  AlertArea+Polygon.swift
//  Chinook
//
//  Created by Gary Kash on 2020-12-21.
//

import CoreGraphics
import Foundation

public extension AlertArea {
    /// The area's polygon as a closed path (x is longitude, y is latitude). Points that don't parse are skipped.
    var cgPath: CGPath {
        let path = CGMutablePath()
        var isFirstPoint = true

        for latLonString in polygon.components(separatedBy: " ") {
            let latLon = latLonString.components(separatedBy: ",")

            guard latLon.count == 2,
                  let latitude = Double(latLon[0]),
                  let longitude = Double(latLon[1]) else { continue }

            let point = CGPoint(latitude: latitude, longitude: longitude)

            if isFirstPoint {
                path.move(to: point)
                isFirstPoint = false
            }
            else {
                path.addLine(to: point)
            }
        }

        path.closeSubpath()

        return path
    }

    func inEffectFor(siteData: SiteData) -> Bool {
        guard let point = siteData.point else { return false }
        return cgPath.contains(point)
    }
}
