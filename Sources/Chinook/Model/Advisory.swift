//
//  Advisory.swift
//  Chinook
//
//  Created by Gary Kash on 2020-12-26.
//

import Foundation

public struct Advisory: Sendable {

    // MARK: Public Properties
    public let designationCode: String
    public let effective: Date?
    public let expires: Date?
    public let urgency: String
    public let severity: String
    public let headline: String?
    public let description: String
    public let areas: Set<AlertArea>
    public let shortDescription: String
    
    // MARK: - Lifecycle
    /// - Parameter now: The moment advisories are judged against; injectable so time is a seam.
    public init(designationCode: String, alertInfos: [AlertInfo], now: Date = Date()) {
        self.designationCode = designationCode
        
        var mutableEffective: Date?
        var mutableExpires: Date?
        var mutableUrgency: String = ""
        var mutableSeverity: String = ""
        var mutableHeadline: String?
        var mutableDescription: String = ""
        var mutableAreas: Set = Set<AlertArea>()
        
        let sortedAlertInfos = alertInfos.sorted { $0.capCount < $1.capCount }

        for alertInfo in sortedAlertInfos {
            if alertInfo.isInEffect(at: now) {
                // active
                mutableEffective = alertInfo.effectiveDate
                mutableExpires = alertInfo.expiresDate
                mutableUrgency = alertInfo.urgency
                mutableSeverity = alertInfo.severity
                mutableHeadline = alertInfo.headline
                mutableDescription = alertInfo.description
                
                for area in alertInfo.area {
                    mutableAreas.insert(area)
                }
            }
            else {
                // expired, or "AllClear"
                for area in alertInfo.area {
                    mutableAreas.remove(area)
                }
            }
        }
        
        effective = mutableEffective
        expires = mutableExpires
        urgency = mutableUrgency
        severity = mutableSeverity
        headline = mutableHeadline
        description = mutableDescription
        shortDescription = description.components(separatedBy: "\n\n###\n\n")[0]
        areas = mutableAreas
    }
}

public extension Advisory {
    /// Groups the alerts' infos for `language` by designation code into advisories, ordered by code.
    static func advisories(from alerts: [Alert], language: Language, now: Date = Date()) -> [Advisory] {
        let alertInfos = alerts.alertInfos(forLanguage: language)
        let designationCodes = Set(alertInfos.compactMap { $0.designationCode })

        return designationCodes.sorted().map { designationCode in
            Advisory(designationCode: designationCode, alertInfos: alertInfos.filter { $0.designationCode == designationCode }, now: now)
        }
    }
}

public extension Array where Element == Advisory {
    /// The advisories with at least one area covering the site. Each advisory appears once, however many of its areas match.
    func inEffectFor(siteData: SiteData) -> [Advisory] {
        filter { advisory in
            advisory.areas.contains { $0.inEffectFor(siteData: siteData) }
        }
    }
}

public extension Array where Element == Alert {
    func alertInfos(forLanguage language: Language) -> [AlertInfo] {
        map({ $0.info })
            .reduce([], +).filter({ $0.language == language.rawValue })
            .sorted(by: { $0.capCount < $1.capCount })
    }
}
