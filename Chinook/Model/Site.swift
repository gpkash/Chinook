//
//  Site.swift
//  Chinook
//
//  Created by Gary Kash on 2020-02-01.
//  Copyright © 2020 Gary Kash. All rights reserved.
//

import Foundation

struct Site: XMLDecodable {
    let code: String
    let nameEn: String
    let nameFr: String
    let provinceCode: String
}
