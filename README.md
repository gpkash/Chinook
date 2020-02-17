# Chinook

Chinook wraps parts of Environment Canada's weather API to make fetching Canadian weather details trivial.

## Requirements

## Installation

Chinook is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'Chinook'
```

## Example

There are two ways you can interact with Chinook's API.

### 1. Using `Operations` (recommended)

This is the easiest way to fetch weather data using Chinook. It provides you with some convenience Operations that wrap up all of the dirty work.

#### Site List:
```swift
let operation = FetchCityPageWeatherSiteListOperation()

operation.completionHandler = { result in

    switch result {
    case .success(let siteList):
        let siteList = siteList as! SiteList

        print("\(siteList.site.count) sites fetched.")

    case .failure(let error):
        // Network or XML parsing issue.
    }
}

queue.addOperation(operation)
```

#### City Page Weather:
```swift
let operation = FetchCityPageWeatherSiteDataOperation(site: site)
operation.completionHandler = { result in

    switch result {
    case .success(let siteData):
        let siteData = siteData as! SiteData

        if let temperature = siteData.currentConditions?.temperature.value {
            print("\(temperature)C, \(location.name.value), \(location.province)")
        }
        else {
            print("N/A, \(location.name.value), \(location.province)")
        }

    case .failure(let error):
        // Network or XML parsing issue.
    }
}

queue.addOperation(operation)

```

### 2. Using the `DataLoader` directly

Alternatively, you can roll your own solution by fetching data directly using the `DataLoader`.

#### Site List:
```swift
let dataLoader = DataLoader()

dataLoader.request(.citypageWeatherSiteList) { result in
    switch result {
    case .success(let data):
        do {
            let siteList = try SiteList.decode(fromXML: data)

            print("\(siteList.site.count) sites fetched.")
        }
        catch {
            // Parsing failed.
        }

    case .failure(let error):
        // Network call failed.
    }
}
```

#### City Page Weather:

```swift
let endpoint = Endpoint.cityPageWeather(forSite: site)

dataLoader.request(endpoint) { [weak self] result in
    switch result {
    case .success(let data):
        do {
            let siteData = try SiteData.decode(fromXML: data)

            print("Loaded city page weather for \(siteData.location.name)")
        }
        catch {
          // Parsing failed.
        }

    case .failure(let error):
        // Network call failed.
    }
}
```

## Future Improvements

Planning to add more endpoints. Enjoy!

## Author

gpkash, capikaw@gmail.com

## License

chinook is available under the MIT license. See the LICENSE file for more info.
