//
//  Alert+Contains.swift
//  Chinook
//
//  Created by Gary Kash on 2020-12-21.
//

import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
import CoreGraphics
#endif

// UIKit implementation
#if canImport(UIKit)
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
#endif

#if canImport(AppKit)
public extension AlertArea {
    var bezierPath: NSBezierPath {
        let path = NSBezierPath()
        var isFirstPoint = true

        for latLonString in polygon.components(separatedBy: " ") {
            let latLon = latLonString.components(separatedBy: ",")

            guard latLon.count == 2,
                  let latitude = Double(latLon[0]),
                  let longitude = Double(latLon[1]) else { continue }

            let point = NSPoint(x: longitude, y: latitude)

            if isFirstPoint {
                path.move(to: point)
                isFirstPoint = false
            } else {
                path.line(to: point)
            }
        }

        path.close()
        return path
    }

    func inEffectFor(siteData: SiteData) -> Bool {
        guard let point = siteData.point else { return false }
        // Use CGPath-based hit-testing for consistent behavior
        return bezierPath.cgPath.contains(point)
    }
}

// Convert NSBezierPath to CGPath for reliable hit-testing
private extension NSBezierPath {
    var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [NSPoint](repeating: .zero, count: 3)
        for i in 0..<self.elementCount {
            let type = self.element(at: i, associatedPoints: &points)
            switch type {
            case .moveTo:
                path.move(to: CGPoint(x: points[0].x, y: points[0].y))
                
            case .lineTo:
                path.addLine(to: CGPoint(x: points[0].x, y: points[0].y))
                
            case .quadraticCurveTo:
                path.addQuadCurve(to: CGPoint(x: points[1].x, y: points[1].y),
                                   control: CGPoint(x: points[0].x, y: points[0].y))
                
            case .cubicCurveTo:
                path.addCurve(to: CGPoint(x: points[2].x, y: points[2].y),
                              control1: CGPoint(x: points[0].x, y: points[0].y),
                              control2: CGPoint(x: points[1].x, y: points[1].y))
                
            case .curveTo:
                path.addCurve(to: CGPoint(x: points[2].x, y: points[2].y),
                              control1: CGPoint(x: points[0].x, y: points[0].y),
                              control2: CGPoint(x: points[1].x, y: points[1].y))
                
            case .closePath:
                path.closeSubpath()
                
            @unknown default:
                break
            }
        }
        
        return path
    }
}
#endif

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
