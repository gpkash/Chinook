//
//  ObservationCollection.swift
//  Chinook
//
//  Created by Gary Kash on 2020-03-21.
//

import Foundation

public struct ObservationCollection: XMLDecodable {
    public struct Member: XMLDecodable {
        public let observation: Observation
    }

    public let member: [Member]
}

public struct IdentificationElements: XMLDecodable {
    public struct IdentificationElement: XMLDecodable {
        public struct Qualifier: XMLDecodable {
            public let name: String
            public let uom: String
            public let value: String
        }
        
        public let name: String?
        public let uom: String?
        public let value: String?
        public let qualifier: Qualifier?
    }

    public let element: [IdentificationElement]
}

public struct Observation: XMLDecodable {
    public struct Metadata: XMLDecodable {
        public struct MetadataSet: XMLDecodable {
            public let identificationElements: IdentificationElements
        }

        public let set: MetadataSet
    }
    
    public struct SamplingTime: XMLDecodable {
        public let timeInstant: TimeInstant
    }

    public struct TimeInstant: XMLDecodable {
        public let timePosition: String
    }

    public struct FeatureOfInterest: XMLDecodable {
        public struct FeatureCollection: XMLDecodable {
            public struct FeatureCollectionLocation: XMLDecodable {
                public struct Point: XMLDecodable {
                    public let pos: String?
                }

                public let point: Point
            }

            public let location: FeatureCollectionLocation
        }

        public let featureCollection: FeatureCollection
    }
    
    public struct Result: XMLDecodable {

        public let elements: IdentificationElements
    }

    public let metadata: Metadata
    public let samplingTime: SamplingTime
    public let resultTime: SamplingTime
    public let featureOfInterest: FeatureOfInterest
}
