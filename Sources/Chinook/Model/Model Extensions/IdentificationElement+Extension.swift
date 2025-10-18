//
//  IdentificationElement+Extension.swift
//  Chinook
//
//  Created by Gary Kash on 2020-03-22.
//

import Foundation

extension IdentificationElements {
    private struct ElementKeys {
        static let stationNameKey = "station_name"
        static let latitudeKey = "latitude"
        static let longitudeKey = "longitude"
        static let transportCanadaIDKey = "transport_canada_id"
        static let observationDateUTCKey = "observation_date_utc"
        static let observationDateLocalTimeKey = "observation_date_local_time"
        static let climateStationNumberKey = "climate_station_number"
        static let wmoStationNumberKey = "wmo_station_number"
    }
    
    var stationName: String? { return element.filter({ $0.name == ElementKeys.stationNameKey }).first?.value }
    var latitude: String? { return element.filter({ $0.name == ElementKeys.latitudeKey }).first?.value }
    var longitude: String? { return element.filter({ $0.name == ElementKeys.longitudeKey }).first?.value }
    var transportCanadaID: String? { return element.filter({ $0.name == ElementKeys.transportCanadaIDKey }).first?.value }
    var observationDateUTC: String? { return element.filter({ $0.name == ElementKeys.observationDateUTCKey }).first?.value }
    var observationDateLocalTime: String? { return element.filter({ $0.name == ElementKeys.observationDateLocalTimeKey }).first?.value }
    var climateStationNumber: String? { return element.filter({ $0.name == ElementKeys.climateStationNumberKey }).first?.value }
    var wmoStationNumber: String? { return element.filter({ $0.name == ElementKeys.wmoStationNumberKey }).first?.value }
}
