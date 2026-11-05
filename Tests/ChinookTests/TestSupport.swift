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
    private var recordedRequests: [URL] = []
    private var inFlight = 0
    private var peakInFlight = 0

    /// How long each request takes, so tests can overlap them.
    var delay: Duration = .zero

    func stub(_ urlString: String, status: Int = 200, body: String = "") {
        lock.withLock { stubs[urlString] = .http(status: status, body: Data(body.utf8)) }
    }

    func stubNonHTTP(_ urlString: String) {
        lock.withLock { stubs[urlString] = .nonHTTP }
    }

    var requests: [URL] { lock.withLock { recordedRequests } }
    var maxInFlight: Int { lock.withLock { peakInFlight } }

    func data(from url: URL) async throws -> (Data, URLResponse) {
        let stub = begin(url)
        defer { end() }

        if delay > .zero {
            try await Task.sleep(for: delay)
        }

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
            return stubs[url.absoluteString]
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
