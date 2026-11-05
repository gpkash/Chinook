//
//  Notification+Typed.swift
//  Chinook
//

import Foundation

/// Typed views of what the repositories post, so observers don't cast `object` themselves.
///
/// Repositories post from the thread of the task that fetched, not the main thread; observers that
/// touch UI should hop to the main queue (for example `.receive(on: DispatchQueue.main)`).
public extension Notification {
    /// The `SiteData` posted on a site's `siteDataUpdatedNotification`.
    var siteData: SiteData? { object as? SiteData }

    /// The `SiteList` posted on `WeatherRepository.Notifications.siteListUpdated`.
    var siteList: SiteList? { object as? SiteList }

    /// The advisories posted on `AlertRepository.Notifications.advisoriesUpdated`.
    var advisories: [Advisory]? { object as? [Advisory] }
}
