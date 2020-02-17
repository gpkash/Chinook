//
//  SiteData.swift
//  Chinook
//
//  Created by Gary Kash on 2020-02-02.
//  Copyright © 2020 Gary Kash. All rights reserved.
//

import Foundation

public struct SiteData: XMLDecodable {
    
    public struct HourlyForecastGroup: XMLDecodable {
        public let dateTime: [DateTime]
        public let hourlyForecast: [HourlyForecast]
    }

    public struct HourlyForecast: XMLDecodable {
        public let dateTimeUTC: String
        public let condition: String
        public let iconCode: IconCode
        public let temperature: Measurement
        public let lop: Measurement
        public let windChill: Measurement
        public let humidex: Measurement
        public let wind: Wind
    }
    
    public struct YesterdayConditions: XMLDecodable {
        public let temperature: [Measurement]?
        public let precip: Measurement?
    }

    public struct RiseSet: XMLDecodable {
        public let disclaimer: String
        public let dateTime: [DateTime]
    }

    public struct Almanac: XMLDecodable {
        public let temperature: [Measurement]
        public let precipitation: [Measurement]
        public let pop: Measurement
    }
    
    public struct Warnings: XMLDecodable {
        
        public struct Event: XMLDecodable {
            public let type: String
            public let priority: String
            public let description: String
            
            public let dateTime: [DateTime]
        }
        
        public let url: String
        public let event: [Event]
    }

    public let dateTime: [DateTime]
    public let location: Location
    public let warnings: Warnings?
    public let currentConditions: CurrentConditions?
    public let forcastGroup: ForecastGroup?
    public let yesterdayConditions: YesterdayConditions?
    public let riseSet: RiseSet?
    public let almanac: Almanac?
}

public struct DateTime: XMLDecodable {
    public let name: String
    public let zone: String
    public let UTCOffset: String
    public let year: Int
    public let month: Int
    public let day: Int
    public let hour: Int
    public let minute: Int
    public let timeStamp: Double
    public let textSummary: String
}

public struct Location: XMLDecodable {
    
    public struct Name: XMLDecodable {
        public let value: String
        public let lat: String
        public let lon: String
    }
    
    public let continent: String
    public let country: String
    public let province: String
    public let name: Name
    public let region: String?
}

public struct Measurement: XMLDecodable {
    public let value: String?
    public let index: String?
    public let unitType: String?
    public let units: String?
    public let `class`: String?
    public let category: String?
    public let period: String?
    public let year: String?
}

public struct Pressure: XMLDecodable {
    public let value: Float?
    public let unitType: String
    public let units: String
    public let change: String
    public let tendency: String
}

public struct CurrentConditions: XMLDecodable {
    
    public struct Station: XMLDecodable {
        public let value: String
        public let code: String
        public let lat: String
        public let lon: String
    }
        
    public let station: Station
    public let dateTime: [DateTime]
    public let condition: String?
    public let iconCode: IconCode?
    public let temperature: Measurement
    public let dewpoint: Measurement
    public let pressure: Pressure
    public let visibility: Measurement
    public let relativeHumidity: Measurement
    public let windChill: Measurement?
    public let wind: Wind
}

public struct ForecastGroup: XMLDecodable {
    
    public struct RegionalNormals: XMLDecodable {
        public let textSummary: String
        public let temperature: [Measurement]
    }

    public let dateTime: [DateTime]
    public let regionalNormals: RegionalNormals
    public let forecast: [Forecast]
}

public struct Forecast: XMLDecodable {

    public struct Period: XMLDecodable {
        public let value: String
        public let textForecastName: String
    }
    
    public struct CloudPrecip: XMLDecodable {
        public let textSummary: String
    }
    
    public struct AbbreviatedForecast: XMLDecodable {
        public let iconCode: IconCode
        public let pop: Measurement
        public let textSummary: String
    }
    
    public struct Temperatures: XMLDecodable {
        public let textSummary: String
        public let temperature: Measurement
    }
    
    public struct Winds: XMLDecodable {
        public let textSummary: String
        public let wind: [Wind]
    }
    
    public struct Precipitation: XMLDecodable {
        public let textSummary: String?
        public let precipType: PrecipType
    }
    
    public let period: Period
    public let textSummary: String
    public let cloudPrecip: CloudPrecip
    public let abbreviatedForecast: AbbreviatedForecast
    public let temperatures: Temperatures
    public let winds: Winds
    public let humidex: String // This needs to be clarified.
    public let precipitation: Precipitation
    public let windChill: WindChill
    public let relativeHumidity: Measurement
}

public struct IconCode: XMLDecodable {
    public let value: String?
    public let format: String?
}

public struct Wind: XMLDecodable {
    
    public struct Direction: XMLDecodable {
        public let value: String
        public let windDirFull: String?
    }

    public let index: Int?
    public let rank: String?
    public let speed: Measurement
    public let gust: Measurement
    public let direction: Direction?
    public let bearing: Measurement
}

public struct PrecipType: XMLDecodable {
    public let start: String
    public let end: String
}

public struct WindChill: XMLDecodable {
    public let textSummary: String?
    public let calculated: [Measurement]
}

