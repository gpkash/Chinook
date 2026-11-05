# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- `DataLoader` is one module owning the disk cache, the fallback rules, a shared `URLSession` and a cap (8) on concurrent requests; its transport is the only seam, so tests use a fake.
- `CityPageLocator` owns finding a site's newest city page: hour arithmetic, listing parsing, a 60 s listing cache shared across sites, and fallback to the previous hour.
- `decodeLenient` on `KeyedDecodingContainer`: one decoding policy for fields EC leaves out. `Pressure`, `PrecipType` and `Wind` use it.
- `Advisory.advisories(from:language:now:)`, and a `now` parameter on `Advisory.init` and `AlertInfo.isActive/isInEffect/isExpired(at:)`: time is a seam.
- `AlertArea.cgPath`, one polygon implementation for iOS, tvOS and macOS.
- Typed `Notification` accessors: `siteData`, `siteList`, `advisories`.
- `Language.preferred(from:)`, `Language.pick(en:fr:)`, `Site.name(in:)`, `Province.name(in:)` and `SiteList.sitesByProvince(in:)`: language is an explicit input.
- Fixture-based tests (live city pages and CAP alerts) and a fake transport; line coverage of `Sources` is above 95%.

### Changed
- `.gitignore` is now a Swift package one; `.DS_Store` and `.swiftpm` are no longer tracked.
- Models conform to `Sendable` (via `XMLDecodable`); the `@unchecked Sendable` extensions are gone.
- Manifests for hours that are over are read from disk once cached; the current and previous hours always refresh.
- Site lists are sorted with `localizedStandardCompare`, so "Île-…" sorts with I.

### Deprecated

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

### Security

## [1.0.0] - 2026-11-05
### Added
- Regression tests for site data decoding.

### Fixed
- Sites whose station isn't reporting (an empty `<currentConditions/>`) no longer fail to decode; `currentConditions` is `nil` and the forecast still loads. Affected ~4% of sites (e.g. Valemount, Williams Lake, Elliot Lake).
- `Location.Name.value` was always `nil` since the move to XMLCoder 0.17; it now decodes the site name.
