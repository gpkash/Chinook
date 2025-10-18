//
//  AnyCodingKey.swift
//  Chinook
//
//  Created by Gary Kash on 2020-03-22.
//

import Foundation

// wrapper to allow us to substitute our mapped string keys.
struct AnyCodingKey : CodingKey {

  var stringValue: String
  var intValue: Int?

  init(_ base: CodingKey) {
    self.init(stringValue: base.stringValue, intValue: base.intValue)
  }

  init(stringValue: String) {
    self.stringValue = stringValue
  }

  init(intValue: Int) {
    self.stringValue = "\(intValue)"
    self.intValue = intValue
  }

  init(stringValue: String, intValue: Int?) {
    self.stringValue = stringValue
    self.intValue = intValue
  }
}
