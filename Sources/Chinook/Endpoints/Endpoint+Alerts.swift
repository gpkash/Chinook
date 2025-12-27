//
//  Endpoint+Alerts.swift
//  Chinook
//
//  Created by Gary Kash on 2020-12-19.
//

import Foundation


extension Endpoint {
    public static func alertsManifest(stationCode: String, day: String, hour: String) -> Endpoint {
        let path = "/today/alerts/cap/\(day)/\(stationCode)/\(hour)" // eg: https://dd.weather.gc.ca/alerts/cap/20201219/CWHX/02/
        return Endpoint(host: .datamart, path: path)
    }

    public static func alert(url: URL) -> Endpoint {
        return Endpoint(url: url)
    }
}
