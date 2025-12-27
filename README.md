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

### Fetching Observation Collection

```swift
do {
    let observations = try await WeatherRepository.fetchObservationCollection(
        forProvince: "ON",
        strategy: .diskWithNetworkFallback
    )
    // Process observations
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

### Data Loading Strategies

Chinook supports three loading strategies via `DataLoaderStrategy`:

- **`.diskOnly`** — Load only from cache
- **`.networkOnly`** — Fetch from network (caches on success)
- **`.diskWithNetworkFallback`** — Try cache first, fall back to network

### Notifications

You can observe data updates via `NotificationCenter`:

```swift
NotificationCenter.default.addObserver(
    forName: WeatherRepository.Notifications.siteListUpdated,
    object: nil,
    queue: .main
) { notification in
    if let siteList = notification.object as? SiteList {
        // Handle updated site list
    }
}
```


## Author

Gary Kash, capikaw@gmail.com

## License

chinook is available under the MIT license. See the LICENSE file for more info.
