//
//  Advisory.swift
//  Chinook
//
//  Created by Gary Kash on 2020-12-26.
//

import Foundation

public struct Advisory {

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
    public init(designationCode: String, alertInfos: [AlertInfo]) {
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
            if alertInfo.isInEffect {
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
