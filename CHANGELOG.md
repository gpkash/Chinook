# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added

### Changed

### Deprecated

### Removed

### Fixed

### Security

## [1.2.0] - 2026-11-06
How a calendar month went at a site's station, next to the 1981–2010 normals. Nothing here changes existing behaviour.

### Added
- `ClimateRepository.fetchMonthlySummary(forSiteData:year:month:strategy:)`: how a calendar month went at a site's station (average high and low, warmest and coldest day, snowfall) next to the 1981–2010 normals for that month. Snowfall is nil where the station doesn't measure it, which is many of them (Winnipeg, Regina, Saskatoon and Quebec City among the airports). Normals are nil where EC publishes none near the site. The strategy applies to the year's daily file, which grows daily; the station list and normals are read from disk first.
- `DailyObservations` and `ClimateNormals` decode the Datamart daily and normals files (`Endpoint.climateDaily` and `climateNormals`).
- `ClimateStation.monthlyYears` and `ClimateStations.normalsStations(for:)`: stations near a site that probably have normals, nearest first. The station that reports daily is often not the one the normals were built from (Winnipeg's airport is `5023227`, its normals are under `5023222`).

### Changed

### Deprecated

### Removed

### Fixed

### Security

## [1.1.0] - 2026-11-05
Climate data from Datamart: a site's daily temperature records, and the station that observed its weather in a given year. Nothing here changes existing behaviour.

### Added
- Datamart climate endpoints: `Endpoint.climateDaily(province:climateID:year:)`, `climateNormals(province:climateID:)`, `climateRecords(province:virtualClimateID:)`, `climateStationList(language:)` and `climateRecordStations`. Daily observations and normals are only named here; decoding them is not part of Chinook yet.
- `ClimateRepository.fetchTemperatureRecords(forSite:strategy:)`: a site's record high and low (and coldest high, warmest low) for every calendar day, with the year each was set. It works for any site EC keeps records for (733 of 855 today) and throws `ClimateError.noRecordStation` for the rest.
- `ClimateRecordStations` finds a site's record series by province and name; `TemperatureRecords.records(on:)` and `records(month:day:)` look up a day.
- `ClimateRepository.fetchClimateStation(forSiteData:year:strategy:)`: the station that observed a site's weather in a given year, so `climateID` and `province` name that year's daily file. A city's station is often replaced by one with a new ID (Winnipeg's airport is `5023222` until 2008, `5023227` since 2018), so the year is part of the question. It looks near the station measuring the site's current conditions, and throws `ClimateError.noClimateStation` when none within 25 km reported that year.
- `ClimateStation` and `ClimateStations`: the station list, with `station(for:year:)` and `station(nearLatitude:longitude:year:)`.
- `CSVTable`, an internal reader for Datamart's CSV files (quoted fields, stray trailing commas, Latin-1).

### Changed
- `SiteData.point` shares its coordinate parsing with the new `SiteData.observationPoint`; behaviour is unchanged.

### Deprecated

### Removed

### Fixed

### Security

### Deprecated

### Removed

### Fixed

### Security

## [1.0.0] - 2026-11-05
The first stable release. Breaking changes are relative to 0.0.7.

### Added
- `DataLoader` is one module owning the disk cache, the fallback rules, a shared `URLSession` and a cap (8) on concurrent requests; its transport is the only seam, so tests use a fake.
- `CityPageLocator` owns finding a site's newest city page: hour arithmetic, listing parsing, a 60 s listing cache shared across sites, and fallback to the previous hour.
- `decodeLenient` on `KeyedDecodingContainer`: one decoding policy for fields EC leaves out. `Pressure`, `PrecipType` and `Wind` use it.
- `Advisory.advisories(from:language:now:)`, and a `now` parameter on `Advisory.init` and `AlertInfo.isActive/isInEffect/isExpired(at:)`: time is a seam.
- `AlertArea.cgPath`, one polygon implementation for iOS, tvOS and macOS.
- Typed `Notification` accessors: `siteData`, `siteList`, `advisories`.
- `Language.preferred(from:)`, `Language.pick(en:fr:)`, `Site.name(in:)`, `Province.name(in:)` and `SiteList.sitesByProvince(in:)`: language is an explicit input.
- Fixture-based tests (live city pages and CAP alerts) and a fake transport; line coverage of `Sources` is above 95%.
- Regression tests for site data decoding.

### Changed
- `.gitignore` is now a Swift package one; `.DS_Store` and `.swiftpm` are no longer tracked.
- Models conform to `Sendable` (via `XMLDecodable`); the `@unchecked Sendable` extensions are gone.
- Manifests for hours that are over are read from disk once cached; the current and previous hours always refresh.
- Site lists are sorted with `localizedStandardCompare`, so "Île-…" sorts with I.

### Removed
- **Breaking:** `WeatherRepository.fetchObservationCollection`, `ObservationCollection` and its types, `WeatherRepository.Notifications.observationCollectionUpdated`. Nothing called them.
- **Breaking:** `AlertArea.bezierPath` (UIKit/AppKit types); use `cgPath`.
- **Breaking:** `Site.SiteDataUpdatedNotificationKeys` (unused).
- Unused helpers: `String` extensions, `FileManager.createPathIfNeeded`, `Date` conveniences.
- `DataLoading`, `NetworkLoader`, `DiskLoader` and their state actors.

### Fixed
- `.diskWithNetworkFallback` now falls back to the network: `DiskLoaderError` was caught but never thrown.
- Cancelling one request no longer cancels another (the loaders kept one static "active task" slot).
- A site is no longer lost when its file isn't in the current hour's directory yet; the previous hour is tried.
- A directory listing fetched before EC finished publishing was cached for a day; listings now live 60 s.
- A cached listing of the current hour hid new alerts until the next hour.
- `Advisory` lists (`inEffectFor`) returned an advisory once per matching area; now once.
- `Endpoint(url:)` dropped the URL's scheme and defaulted to http; it now keeps it.
- `AlertRepository.Notifications.advisoriesUpdated` carried the string "WeatherRepository"; it now says "AlertRepository".
- `Province.count` was hard-coded; "Price Edward Island" is now "Prince Edward Island".
- Sites whose station isn't reporting (an empty `<currentConditions/>`) no longer fail to decode; `currentConditions` is `nil` and the forecast still loads. Affected ~4% of sites (e.g. Valemount, Williams Lake, Elliot Lake).
- `Location.Name.value` was always `nil` since the move to XMLCoder 0.17; it now decodes the site name.
