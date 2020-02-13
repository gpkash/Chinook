//
//  SiteData.swift
//  Chinook
//
//  Created by Gary Kash on 2020-02-02.
//  Copyright © 2020 Gary Kash. All rights reserved.
//

import Foundation

struct SiteData: XMLDecodable {
    
    struct HourlyForecastGroup: XMLDecodable {
        let dateTime: [DateTime]
        let hourlyForecast: [HourlyForecast]
    }

    struct HourlyForecast: XMLDecodable {
        let dateTimeUTC: String
        let condition: String
        let iconCode: IconCode
        let temperature: Measurement
        let lop: Measurement
        let windChill: Measurement
        let humidex: Measurement
        let wind: Wind
    }
    
    struct YesterdayConditions: XMLDecodable {
        let temperature: [Measurement]?
        let precip: Measurement?
    }

    struct RiseSet: XMLDecodable {
        let disclaimer: String
        let dateTime: [DateTime]
    }

    struct Almanac: XMLDecodable {
        let temperature: [Measurement]
        let precipitation: [Measurement]
        let pop: Measurement
    }
    
    struct Warnings: XMLDecodable {
        
        struct Event: XMLDecodable {
            let type: String
            let priority: String
            let description: String
            
            let dateTime: [DateTime]
        }
        
        let url: String
        let event: [Event]
    }

    let dateTime: [DateTime]
    let location: Location
    let warnings: Warnings?
    let currentConditions: CurrentConditions?
    let forcastGroup: ForecastGroup?
    let yesterdayConditions: YesterdayConditions?
    let riseSet: RiseSet?
    let almanac: Almanac?
}

struct DateTime: XMLDecodable {
    let name: String
    let zone: String
    let UTCOffset: String
    let year: Int
    let month: Int
    let day: Int
    let hour: Int
    let minute: Int
    let timeStamp: Double
    let textSummary: String
}

struct Location: XMLDecodable {
    
    struct Name: XMLDecodable {
        let value: String
        let lat: String
        let lon: String
    }
    
    let continent: String
    let country: String
    let province: String
    let name: Name
    let region: String?
}

struct Measurement: XMLDecodable {
    let value: String?
    let index: String?
    let unitType: String?
    let units: String?
    let `class`: String?
    let category: String?
    let period: String?
    let year: String?
}

struct Pressure: XMLDecodable {
    let value: Float?
    let unitType: String
    let units: String
    let change: String
    let tendency: String
}

struct CurrentConditions: XMLDecodable {
    
    struct Station: XMLDecodable {
        let value: String
        let code: String
        let lat: String
        let lon: String
    }
        
    let station: Station
    let dateTime: [DateTime]
    let condition: String?
    let iconCode: IconCode?
    let temperature: Measurement
    let dewpoint: Measurement
    let pressure: Pressure
    let visibility: Measurement
    let relativeHumidity: Measurement
    let windChill: Measurement?
    let wind: Wind
}

struct ForecastGroup: XMLDecodable {
    
    struct RegionalNormals: XMLDecodable {
        let textSummary: String
        let temperature: [Measurement]
    }

    let dateTime: [DateTime]
    let regionalNormals: RegionalNormals
    let forecast: [Forecast]
}

struct Forecast: XMLDecodable {

    struct Period: XMLDecodable {
        let value: String
        let textForecastName: String
    }
    
    struct CloudPrecip: XMLDecodable {
        let textSummary: String
    }
    
    struct AbbreviatedForecast: XMLDecodable {
        let iconCode: IconCode
        let pop: Measurement
        let textSummary: String
    }
    
    struct Temperatures: XMLDecodable {
        let textSummary: String
        let temperature: Measurement
    }
    
    struct Winds: XMLDecodable {
        let textSummary: String
        let wind: [Wind]
    }
    
    struct Precipitation: XMLDecodable {
        let textSummary: String?
        let precipType: PrecipType
    }
    
    let period: Period
    let textSummary: String
    let cloudPrecip: CloudPrecip
    let abbreviatedForecast: AbbreviatedForecast
    let temperatures: Temperatures
    let winds: Winds
    let humidex: String // This needs to be clarified.
    let precipitation: Precipitation
    let windChill: WindChill
    let relativeHumidity: Measurement
}

struct IconCode: XMLDecodable {
    let value: String?
    let format: String?
}

struct Wind: XMLDecodable {
    
    struct Direction: XMLDecodable {
        let value: String
        let windDirFull: String?
    }

    let index: Int?
    let rank: String?
    let speed: Measurement
    let gust: Measurement
    let direction: Direction?
    let bearing: Measurement
}

struct PrecipType: XMLDecodable {
    let start: String
    let end: String
}

struct WindChill: XMLDecodable {
    let textSummary: String?
    let calculated: [Measurement]
}

