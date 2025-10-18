//
//  KeyDecodingStrategy+ObservationCollection.swift
//  Chinook
//
//  Created by Gary Kash on 2020-03-22.
//

import Foundation
import XMLCoder

extension XMLDecoder.KeyDecodingStrategy {
    static var observationCollectionCustomStrategy: XMLDecoder.KeyDecodingStrategy {
        return .custom { codingKeys in
            var key = AnyCodingKey(codingKeys.last!)
            
            // remove any colon and prefix
            if let lastComponent = key.stringValue.split(separator: ":").last {
                key.stringValue = String(lastComponent)
            }
            
            // remove dashes and replace the components to a capitalized varient
            if key.stringValue.contains("-") {
                let components = key.stringValue.split(separator: "-")
                var newStringValue = ""
                for component in components {
                    newStringValue += String(component).capitalizingFirstLetter()
                }
                key.stringValue = newStringValue
            }
            
            key.stringValue = key.stringValue.lowercasingFirstLetter()
            
            print(key.stringValue)
            
            return key
        }
    }
}
