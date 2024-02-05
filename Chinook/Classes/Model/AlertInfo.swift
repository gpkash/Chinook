//
//  AlertInfo.swift
//  Chinook
//
//  Created by Gary Kash on 2020-12-22.
//

import Foundation

public struct AlertInfo: XMLDecodable, Hashable {
    public let language: String
    public let event: String
    public let responseType: String
    public let urgency: String
    public let severity: String
    public let certainty: String
    public let audience: String
    public let effective: String?
    public let expires: String?
    public let headline: String?
    public let description: String
    public let web: String
    public let parameter: [AlertParameter]
    public let area: [AlertArea]
    
    public var designationCode: String? {
        parameter.filter({ $0.valueName.hasSuffix("Designation_Code") }).first?.value
    }

    public var capCount: Int {
        guard let rawValue = parameter.filter({ $0.valueName.hasSuffix("CAP_count") }).first?.value else { return 0 }
        let components: [String] = rawValue.components(separatedBy: " ")
        guard components.count == 3, let capComponent = components.last?.replacingOccurrences(of: "C:", with: "") else { return 0 }
        
        return Int(capComponent) ?? 0
    }
    
    public static func == (lhs: AlertInfo, rhs: AlertInfo) -> Bool {
        return lhs.language+lhs.event+lhs.responseType+(lhs.effective ?? "")+(lhs.expires ?? "")+lhs.description == rhs.language+rhs.event+rhs.responseType+(rhs.effective ?? "")+(rhs.expires ?? "")+rhs.description
    }
}

extension AlertInfo {
    private static var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(secondsFromGMT:0)
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss-00:00" // eg: 2020-12-21T04:21:30-00:00
        return dateFormatter
    }

    public var effectiveDate: Date? {
        guard let effective else { return nil }
        return Self.dateFormatter.date(from: effective)
    }
    
    public var expiresDate: Date? {
        guard let expires else { return nil }
        return Self.dateFormatter.date(from: expires)
    }

    /// Returns whether the alert is effective and not expired.
    public var isActive: Bool {
        guard let effectiveDate else { return true }
        return effectiveDate <= Date() && !isExpired
    }
    
    /// Returns whether the alert is still going. Aka: active, not clear and not past.
    public var isInEffect: Bool {
        isActive && responseType != "AllClear" && urgency != "Past"
    }
    
    
    public var isExpired: Bool {
        guard let expiresDate else { return false }
        return expiresDate < Date()
    }
}
