//
//  Alert+Contains.swift
//  Chinook
//
//  Created by Gary Kash on 2020-12-21.
//

import Foundation

public extension AlertArea {
    var bezierPath: UIBezierPath {
        let path = UIBezierPath()
        
        for latLonString in polygon.components(separatedBy: " ") {
            let latLon = latLonString.components(separatedBy: ",")
            
            guard latLon.count == 2,
                  let latitude = Double(latLon[0]),
                  let longitude = Double(latLon[1]) else { continue }
            
            let point = CGPoint(x: longitude, y: latitude)
            
            if path.isEmpty {
                path.move(to: point)
            }
            else {
                path.addLine(to: point)
            }
        }
        
        path.close()
        
        return path
    }
    
    func inEffectFor(siteData: SiteData) -> Bool {
        guard let point = siteData.point else { return false }
        return bezierPath.contains(point)
    }
}

public extension Array where Element == Advisory {
    func inEffectFor(siteData: SiteData) -> [Advisory] {
        var advisories: [Advisory] = []

        for advisory in self {
            for area in advisory.areas {
                if area.inEffectFor(siteData: siteData) {
                    advisories.append(advisory)
                }
            }
        }

        return advisories
    }
}

public extension Array where Element == Alert {
    func alertInfos(forLanguage language: Language) -> [AlertInfo] {
        map({ $0.info })
            .reduce([], +).filter({ $0.language == language.rawValue })
            .sorted(by: { $0.capCount < $1.capCount })
    }
}
