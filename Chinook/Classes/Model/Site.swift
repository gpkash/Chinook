//
//  Site.swift
//  Chinook
//
//  Created by Gary Kash on 2020-02-01.
//  Copyright © 2020 Gary Kash. All rights reserved.
//

import Foundation

public struct Site: XMLDecodable {
    public let code: String
    public let nameEn: String
    public let nameFr: String
    public let provinceCode: String
}

extension Site: Equatable {
    /// Environment Canada gives each site a code. This assumes these codes will remain unique.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.code == rhs.code
    }
}
