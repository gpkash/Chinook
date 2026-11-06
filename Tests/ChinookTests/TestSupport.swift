import Testing
import Foundation
@testable import Chinook

/// A `DataTransport` that serves canned responses and records what was asked of it.
final class FakeTransport: DataTransport, @unchecked Sendable {
    enum Stub {
        case http(status: Int, body: Data)
        case nonHTTP
    }

    private let lock = NSLock()
    private var stubs: [String: Stub] = [:]
    private var fallback: Stub?
    private var recordedRequests: [URL] = []
    private var inFlight = 0
    private var peakInFlight = 0
    private var heldURLs: Set<String> = []
    private var heldRequests: [String: [CheckedContinuation<Void, Never>]] = [:]

    /// How long each request takes, so tests can overlap them.
    var delay: Duration = .zero

    func stub(_ urlString: String, status: Int = 200, body: String = "") {
        lock.withLock { stubs[urlString] = .http(status: status, body: Data(body.utf8)) }
    }

    /// For bodies that aren't UTF-8, like the Latin-1 climate files.
    func stub(_ urlString: String, status: Int = 200, data: Data) {
        lock.withLock { stubs[urlString] = .http(status: status, body: data) }
    }

    /// Served for any URL without its own stub.
    func stubEverythingElse(status: Int = 200, body: String = "") {
        lock.withLock { fallback = .http(status: status, body: Data(body.utf8)) }
    }

    /// Requests to this URL are recorded, then suspended until `open` is called for it.
    func hold(_ urlString: String) {
        lock.withLock { _ = heldURLs.insert(urlString) }
    }

    func open(_ urlString: String) {
        let resumable = lock.withLock { () -> [CheckedContinuation<Void, Never>] in
            heldURLs.remove(urlString)
            return heldRequests.removeValue(forKey: urlString) ?? []
        }
        resumable.forEach { $0.resume() }
    }

    func stubNonHTTP(_ urlString: String) {
        lock.withLock { stubs[urlString] = .nonHTTP }
    }

    var requests: [URL] { lock.withLock { recordedRequests } }
    var maxInFlight: Int { lock.withLock { peakInFlight } }

    func data(from url: URL) async throws -> (Data, URLResponse) {
        let stub = begin(url)
        defer { end() }

        await waitWhileHeld(url)

        if delay > .zero {
            try await Task.sleep(for: delay)
        }

        try Task.checkCancellation()

        switch stub {
        case .http(let status, let body):
            return (body, HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!)
        case .nonHTTP:
            return (Data(), URLResponse(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil))
        case nil:
            throw URLError(.fileDoesNotExist)
        }
    }

    private func begin(_ url: URL) -> Stub? {
        lock.withLock {
            recordedRequests.append(url)
            inFlight += 1
            peakInFlight = max(peakInFlight, inFlight)
            return stubs[url.absoluteString] ?? fallback
        }
    }

    private func waitWhileHeld(_ url: URL) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let mustWait = lock.withLock { () -> Bool in
                guard heldURLs.contains(url.absoluteString) else { return false }
                heldRequests[url.absoluteString, default: []].append(continuation)
                return true
            }

            if !mustWait { continuation.resume() }
        }
    }

    private func end() {
        lock.withLock { inFlight -= 1 }
    }
}

/// A scratch cache directory removed when the value goes out of scope of `withCacheDirectory`.
func withCacheDirectory<T>(_ body: (URL) async throws -> T) async rethrows -> T {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("chinook-tests-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: directory) }

    return try await body(directory)
}

func makeEndpoint(_ path: String = "/today/test/file.xml", host: String = "example.test") -> Endpoint {
    Endpoint(host: Host(scheme: "https", hostname: host), path: path)
}

func makeLoader(_ transport: FakeTransport, cacheDirectory: URL, maxConcurrentRequests: Int = 8) -> DataLoader {
    DataLoader(transport: transport, cacheDirectory: cacheDirectory, maxConcurrentRequests: maxConcurrentRequests)
}

/// Loads a file from `Tests/ChinookTests/Fixtures`.
func fixture(_ name: String) throws -> Data {
    let url = Bundle.module.url(forResource: name, withExtension: nil, subdirectory: "Fixtures")
    return try Data(contentsOf: try #require(url, "missing fixture \(name)"))
}

/// A fixed moment: 2026-11-05 at the given UTC hour and minute.
func utc(hour: Int, minute: Int = 0, day: Int = 5) -> Date {
    var components = DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute)
    components.timeZone = TimeZone(secondsFromGMT: 0)

    return Calendar(identifier: .gregorian).date(from: components)!
}

/// A directory listing in the shape Datamart serves.
func capListing(_ files: String...) -> String {
    files.map { "<img src=\"/icons/unknown.gif\"> <a href=\"\($0)\">\($0)</a> 2026-11-05 20:01 17K" }.joined(separator: "\n")
}

func fixtureString(_ name: String) throws -> String {
    String(decoding: try fixture(name), as: UTF8.self)
}

/// City page XML with the location rewritten, for point-in-polygon tests.
func siteData(latitude: String, longitude: String) throws -> SiteData {
    let xml = try fixtureString("citypage-edmonton-en.xml")
        .replacingOccurrences(of: #"lat="53.54N" lon="113.49W""#, with: #"lat="\#(latitude)" lon="\#(longitude)""#)

    return try SiteData.decode(fromXML: Data(xml.utf8))
}

/// Polls until `condition` holds, so tests wait on state rather than on a guess about timing.
func eventually(timeout: Duration = .seconds(5), _ condition: () async -> Bool) async -> Bool {
    let deadline = ContinuousClock.now + timeout

    while ContinuousClock.now < deadline {
        if await condition() { return true }
        try? await Task.sleep(for: .milliseconds(2))
    }

    return await condition()
}

/// A gate that holds callers of `wait()` until `open()`.
actor Latch {
    private var isOpen = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func wait() async {
        if isOpen { return }
        await withCheckedContinuation { waiters.append($0) }
    }

    func open() {
        isOpen = true
        waiters.forEach { $0.resume() }
        waiters = []
    }
}
