//
//  IdentificationElement+Extension.swift
//  Chinook
//
//  Created by Gary Kash on 2020-03-22.
//

import Foundation

extension IdentificationElements {
    private struct ElementKeys {
        static var stationNameKey = "station_name";
        static var latitudeKey = "latitude";
        static var longitudeKey = "longitude";
        static var transportCanadaIDKey = "transport_canada_id";
        static var observationDateUTCKey = "observation_date_utc";
        static var observationDateLocalTimeKey = "observation_date_local_time";
        static var climateStationNumberKey = "climate_station_number";
        static var wmoStationNumberKey = "wmo_station_number";
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
