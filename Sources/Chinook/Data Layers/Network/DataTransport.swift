//
//  DataTransport.swift
//  Chinook
//

import Foundation

/// The seam between the loading module and the network.
///
/// Production uses `URLSessionTransport`; tests substitute a fake.
protocol DataTransport: Sendable {
    func data(from url: URL) async throws -> (Data, URLResponse)
}

struct URLSessionTransport: DataTransport {
    private let session: URLSession

    init(session: URLSession = URLSessionTransport.makeSession()) {
        self.session = session
    }

    /// One session for every request, so connections are reused.
    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.httpMaximumConnectionsPerHost = 8

        return URLSession(configuration: configuration)
    }

    func data(from url: URL) async throws -> (Data, URLResponse) {
        try await session.data(from: url)
    }
}

/// Caps how many requests are in flight at once. Waiters are served in order, and a cancelled
/// waiter leaves the queue without disturbing anyone else.
actor RequestLimiter {
    private let limit: Int
    private var running = 0
    private var waiters: [(id: UUID, continuation: CheckedContinuation<Void, Error>)] = []

    init(limit: Int) {
        self.limit = max(1, limit)
    }

    /// How many permits are held right now. Read by tests so they can wait on state instead of on time.
    var runningCount: Int { running }

    /// How many callers are queued behind the cap. Read by tests, for the same reason.
    var waitingCount: Int { waiters.count }

    func withPermit<T: Sendable>(_ operation: @Sendable () async throws -> T) async throws -> T {
        try await acquire()

        do {
            let result = try await operation()
            release()
            return result
        }
        catch {
            release()
            throw error
        }
    }

    private func acquire() async throws {
        try Task.checkCancellation()

        if running < limit {
            running += 1
            return
        }

        let id = UUID()

        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                waiters.append((id: id, continuation: continuation))
            }
        } onCancel: {
            Task { await self.cancelWaiter(id) }
        }
    }

    private func cancelWaiter(_ id: UUID) {
        guard let index = waiters.firstIndex(where: { $0.id == id }) else { return }

        waiters.remove(at: index).continuation.resume(throwing: CancellationError())
    }

    private func release() {
        if waiters.isEmpty {
            running -= 1
        }
        else {
            // Hand the permit straight to the next waiter.
            waiters.removeFirst().continuation.resume()
        }
    }
}
