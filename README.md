# Chinook

Chinook wraps parts of Environment Canada's weather API to make fetching Canadian weather details trivial.

## Installation

Chinook is available as a Swift Package. Add it to your project via Xcode's Swift Package Manager or add the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/gpkash/Chinook.git", from: "0.0.0")
]
```

## Example

Chinook uses Swift's modern async/await concurrency. The primary way to interact with the API is through the `WeatherRepository` and `AlertRepository`.

### Fetching the Site List

```swift
import Chinook

do {
    let siteList = try await WeatherRepository.fetchCityPageSiteList(strategy: .diskWithNetworkFallback)
    print("\(siteList.site.count) sites fetched.")
} catch {
    // Handle network or parsing error
}
```

### Fetching Weather for a Site

```swift
do {
    let siteData = try await WeatherRepository.fetchWeather(forSite: site, strategy: .networkOnly)
    
    if let temperature = siteData.currentConditions?.temperature.value {
        print("\(temperature)°C")
    }
} catch {
    // Handle error
}
```

### Fetching Weather for Multiple Sites

```swift
do {
    let sites: [Site] = [...] // Your list of sites
    let allSiteData = try await WeatherRepository.fetchWeather(forSites: sites, strategy: .diskWithNetworkFallback)
    
    for siteData in allSiteData {
        print("\(siteData.location.name): \(siteData.currentConditions?.temperature.value ?? "N/A")")
    }
} catch {
    // Handle error
}
```

### Fetching Weather Alerts

```swift
do {
    let advisories = try await AlertRepository.fetchAdvisories()
    
    for advisory in advisories {
        print("Advisory: \(advisory.designationCode)")
    }
} catch {
    // Handle error
}
```

### Fetching Temperature Records

Daily record highs and lows work for any site EC keeps records for (about 86% of them; remote communities are missing).

```swift
do {
    let records = try await ClimateRepository.fetchTemperatureRecords(forSite: site, strategy: .diskWithNetworkFallback)

    if let today = records.records(on: .now) {
        print("Record high \(today.recordHigh?.temperature ?? .nan) in \(today.recordHigh?.year ?? 0)")
        print("Record low \(today.recordLow?.temperature ?? .nan) in \(today.recordLow?.year ?? 0)")
    }
} catch ClimateError.noRecordStation {
    // EC keeps no records for this site.
} catch {
    // Handle network or parsing error
}
```

### Finding the Station for a Site and Year

A site's weather station changes over the years, so the year is part of the question:

```swift
let siteData = try await WeatherRepository.fetchWeather(forSite: site, strategy: .diskWithNetworkFallback)
let station = try await ClimateRepository.fetchClimateStation(forSiteData: siteData, year: 1986, strategy: .diskWithNetworkFallback)

station.climateID // "5023222": Winnipeg Richardson Int'l A, which stopped reporting daily in 2008
```

### Climate Endpoints

`Endpoint` also names the Datamart climate files, for callers that want the raw CSV: `climateDaily(province:climateID:year:)`, `climateNormals(province:climateID:)`, `climateRecords(province:virtualClimateID:)`, `climateStationList(language:)` and `climateRecordStations`. Get a station's `climateID` and `province` from `fetchClimateStation` rather than hard-coding them.

### Data Loading Strategies

Chinook supports three loading strategies via `DataLoaderStrategy`:

- **`.diskOnly`** — Load only from cache
- **`.networkOnly`** — Fetch from network (caches on success)
- **`.diskWithNetworkFallback`** — Try cache first, fall back to network (a missing or unreadable cache entry is not an error)

Requests share one `URLSession` and at most 8 are in flight at once.

### Notifications

You can observe data updates via `NotificationCenter`:

```swift
NotificationCenter.default.addObserver(
    forName: WeatherRepository.Notifications.siteListUpdated,
    object: nil,
    queue: .main
) { notification in
    if let siteList = notification.siteList {
        // Handle updated site list
    }
}
```

Notifications are posted from the thread of the task that fetched, not the main thread. `Notification` has typed
accessors (`siteData`, `siteList`, `advisories`), so there's no need to cast `object`.


## Author

Gary Kash, capikaw@gmail.com

## License

chinook is available under the MIT license. See the LICENSE file for more info.
