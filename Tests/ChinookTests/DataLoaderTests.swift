import Foundation
import Testing
@testable import Chinook

@Suite struct DataLoaderTests {
    // MARK: - Strategies

    @Test func cacheMissFallsBackToNetworkThenServesFromDisk() async throws {
        try await withCacheDirectory { directory in
            let transport = FakeTransport()
            transport.stub("https://example.test/today/test/file.xml", body: "<a/>")
            let loader = makeLoader(transport, cacheDirectory: directory)

            let first = try await loader.request(makeEndpoint(), strategy: .diskWithNetworkFallback)
            let second = try await loader.request(makeEndpoint(), strategy: .diskWithNetworkFallback)

            #expect(first == DataResponse(data: Data("<a/>".utf8), source: .network))
            #expect(second == DataResponse(data: Data("<a/>".utf8), source: .disk))
            #expect(transport.requests.count == 1)
        }
    }

    @Test func defaultStrategyIsDiskWithNetworkFallback() async throws {
        try await withCacheDirectory { directory in
            let transport = FakeTransport()
            transport.stub("https://example.test/today/test/file.xml", body: "x")
            let loader = makeLoader(transport, cacheDirectory: directory)

            _ = try await loader.request(makeEndpoint())
            let again = try await loader.request(makeEndpoint())

            #expect(again.source == .disk)
        }
    }

    @Test func diskOnlyThrowsWhenNothingIsCached() async throws {
        await withCacheDirectory { directory in
            let transport = FakeTransport()
            let loader = makeLoader(transport, cacheDirectory: directory)

            await #expect(throws: DataLoaderError.self) {
                try await loader.request(makeEndpoint(), strategy: .diskOnly)
            }
            #expect(transport.requests.isEmpty)
        }
    }

    @Test func diskOnlyServesWhatNetworkOnlyCached() async throws {
        try await withCacheDirectory { directory in
            let transport = FakeTransport()
            transport.stub("https://example.test/today/test/file.xml", body: "cached")
            let loader = makeLoader(transport, cacheDirectory: directory)

            _ = try await loader.request(makeEndpoint(), strategy: .networkOnly)
            let response = try await loader.request(makeEndpoint(), strategy: .diskOnly)

            #expect(response == DataResponse(data: Data("cached".utf8), source: .disk))
        }
    }

    @Test func networkOnlyAlwaysHitsTheNetwork() async throws {
        try await withCacheDirectory { directory in
            let transport = FakeTransport()
            transport.stub("https://example.test/today/test/file.xml", body: "fresh")
            let loader = makeLoader(transport, cacheDirectory: directory)

            _ = try await loader.request(makeEndpoint(), strategy: .networkOnly)
            let second = try await loader.request(makeEndpoint(), strategy: .networkOnly)

            #expect(second.source == .network)
            #expect(transport.requests.count == 2)
        }
    }

    // MARK: - Failures

    @Test func httpErrorIsThrownAndNothingIsCached() async throws {
        try await withCacheDirectory { directory in
            let transport = FakeTransport()
            transport.stub("https://example.test/today/test/file.xml", status: 404)
            let loader = makeLoader(transport, cacheDirectory: directory)

            do {
                _ = try await loader.request(makeEndpoint(), strategy: .networkOnly)
                Issue.record("expected an HTTP error")
            }
            catch NetworkError.httpError(let statusCode) {
                #expect(statusCode == 404)
            }

            await #expect(throws: DataLoaderError.self) {
                try await loader.request(makeEndpoint(), strategy: .diskOnly)
            }
        }
    }

    @Test func nonHTTPResponseIsAnEmptyResponse() async throws {
        try await withCacheDirectory { directory in
            let transport = FakeTransport()
            transport.stubNonHTTP("https://example.test/today/test/file.xml")
            let loader = makeLoader(transport, cacheDirectory: directory)

            do {
                _ = try await loader.request(makeEndpoint(), strategy: .networkOnly)
                Issue.record("expected an empty response error")
            }
            catch NetworkError.emptyResponse {
            }
        }
    }

    @Test func unbuildableURLIsABadURL() async throws {
        try await withCacheDirectory { directory in
            let loader = makeLoader(FakeTransport(), cacheDirectory: directory)

            do {
                // A host with a relative path can't form a URL.
                _ = try await loader.request(makeEndpoint("no-leading-slash"), strategy: .networkOnly)
                Issue.record("expected a bad URL error")
            }
            catch NetworkError.badURL {
            }
        }
    }

    @Test func transportErrorsPropagate() async throws {
        await withCacheDirectory { directory in
            let loader = makeLoader(FakeTransport(), cacheDirectory: directory)

            await #expect(throws: URLError.self) {
                try await loader.request(makeEndpoint(), strategy: .networkOnly)
            }
        }
    }

    // MARK: - Concurrency

    @Test func concurrentRequestsAreCapped() async throws {
        try await withCacheDirectory { directory in
            let transport = FakeTransport()
            transport.delay = .milliseconds(30)
            let urls = (0..<12).map { "https://example.test/today/test/\($0).xml" }
            urls.forEach { transport.stub($0, body: "ok") }
            let loader = makeLoader(transport, cacheDirectory: directory, maxConcurrentRequests: 3)

            try await withThrowingTaskGroup(of: Void.self) { group in
                for index in 0..<12 {
                    group.addTask { _ = try await loader.request(makeEndpoint("/today/test/\(index).xml"), strategy: .networkOnly) }
                }
                try await group.waitForAll()
            }

            #expect(transport.requests.count == 12)
            #expect(transport.maxInFlight <= 3)
            #expect(transport.maxInFlight > 1)
        }
    }

    @Test func cancellingOneRequestLeavesTheOthersRunning() async throws {
        try await withCacheDirectory { directory in
            let transport = FakeTransport()
            let first = "https://example.test/today/test/a.xml"
            transport.stub(first, body: "a")
            transport.stub("https://example.test/today/test/b.xml", body: "b")
            transport.hold(first)
            let loader = makeLoader(transport, cacheDirectory: directory)

            let firstTask = Task { try await loader.request(makeEndpoint("/today/test/a.xml"), strategy: .networkOnly) }
            let secondTask = Task { try await loader.request(makeEndpoint("/today/test/b.xml"), strategy: .networkOnly) }

            // The first request is in the transport, held; cancel it, then let it go.
            #expect(await eventually { transport.requests.contains(URL(string: first)!) })
            firstTask.cancel()
            transport.open(first)

            await #expect(throws: CancellationError.self) { try await firstTask.value }
            let survivor = try await secondTask.value
            #expect(survivor.data == Data("b".utf8))
        }
    }

    @Test func aCancelledWaiterNeverReachesTheTransportAndFreesItsPlace() async throws {
        try await withCacheDirectory { directory in
            let transport = FakeTransport()
            let held = "https://example.test/today/test/a.xml"
            ["a", "b", "c"].forEach { transport.stub("https://example.test/today/test/\($0).xml", body: $0) }
            transport.hold(held)
            let loader = makeLoader(transport, cacheDirectory: directory, maxConcurrentRequests: 1)

            // The holder takes the only permit and stays in the transport until we open it.
            let holder = Task { try await loader.request(makeEndpoint("/today/test/a.xml"), strategy: .networkOnly) }
            #expect(await eventually { transport.requests.contains(URL(string: held)!) })

            // Whether the waiter is already queued or not yet started, it can't get a permit before the holder lets go.
            let waiter = Task { try await loader.request(makeEndpoint("/today/test/b.xml"), strategy: .networkOnly) }
            waiter.cancel()
            await #expect(throws: CancellationError.self) { try await waiter.value }

            transport.open(held)
            _ = try await holder.value

            let next = try await loader.request(makeEndpoint("/today/test/c.xml"), strategy: .networkOnly)
            #expect(next.data == Data("c".utf8))
            #expect(!transport.requests.contains(URL(string: "https://example.test/today/test/b.xml")!))
        }
    }

    @Test func aQueuedWaiterThatIsCancelledLeavesTheQueue() async throws {
        let limiter = RequestLimiter(limit: 1)
        let latch = Latch()

        let holder = Task { try await limiter.withPermit { await latch.wait() } }
        #expect(await eventually { await limiter.runningCount == 1 })

        let waiter = Task { try await limiter.withPermit { "ran" } }
        #expect(await eventually { await limiter.waitingCount == 1 })

        waiter.cancel()
        await #expect(throws: CancellationError.self) { try await waiter.value }
        #expect(await limiter.waitingCount == 0)

        await latch.open()
        _ = try await holder.value

        #expect(await limiter.runningCount == 0)
        #expect(try await limiter.withPermit { "next" } == "next")
    }

    @Test func waitersAreServedInOrder() async throws {
        let limiter = RequestLimiter(limit: 1)
        let latch = Latch()
        let order = Posted<[Int]>()
        order.set([])

        let holder = Task { try await limiter.withPermit { await latch.wait() } }
        #expect(await eventually { await limiter.runningCount == 1 })

        var waiters: [Task<Void, Error>] = []
        for index in 1...3 {
            waiters.append(Task {
                try await limiter.withPermit { order.set((order.value ?? []) + [index]) }
            })
            #expect(await eventually { await limiter.waitingCount == index })
        }

        await latch.open()
        _ = try await holder.value
        for waiter in waiters { try await waiter.value }

        #expect(order.value == [1, 2, 3])
    }

    @Test func alreadyCancelledRequestsNeverStart() async throws {
        let limiter = RequestLimiter(limit: 1)

        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await limiter.withPermit { 1 }
        }

        await #expect(throws: CancellationError.self) { try await task.value }
    }

    @Test func limiterReleasesItsPermitWhenTheOperationThrows() async throws {
        let limiter = RequestLimiter(limit: 1)

        await #expect(throws: URLError.self) {
            try await limiter.withPermit { throw URLError(.badServerResponse) }
        }

        let value = try await limiter.withPermit { 42 }
        #expect(value == 42)
    }

    @Test func limiterTreatsAZeroLimitAsOne() async throws {
        let limiter = RequestLimiter(limit: 0)

        #expect(try await limiter.withPermit { "ran" } == "ran")
    }

    // MARK: - Cache housekeeping

    @Test func cacheWriteReplacesAFileSittingWhereADirectoryShouldBe() async throws {
        try await withCacheDirectory { directory in
            let transport = FakeTransport()
            transport.stub("https://example.test/today/test/file.xml", body: "data")
            let loader = makeLoader(transport, cacheDirectory: directory)
            let fm = FileManager.default

            let blocker = directory.appendingPathComponent("today/test")
            try fm.createDirectory(at: blocker.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data("legacy".utf8).write(to: blocker)

            _ = try await loader.request(makeEndpoint(), strategy: .networkOnly)
            let cached = try await loader.request(makeEndpoint(), strategy: .diskOnly)

            #expect(cached.data == Data("data".utf8))
        }
    }

    @Test func cacheWriteReplacesADirectorySittingWhereAFileShouldBe() async throws {
        try await withCacheDirectory { directory in
            let transport = FakeTransport()
            transport.stub("https://example.test/today/test/file.xml", body: "data")
            let loader = makeLoader(transport, cacheDirectory: directory)

            let blocker = loader.storageURL(for: makeEndpoint())
            try FileManager.default.createDirectory(at: blocker, withIntermediateDirectories: true)

            _ = try await loader.request(makeEndpoint(), strategy: .networkOnly)
            let cached = try await loader.request(makeEndpoint(), strategy: .diskOnly)

            #expect(cached.data == Data("data".utf8))
        }
    }

    @Test func anUnwritableCacheDoesNotFailTheLoad() async throws {
        let transport = FakeTransport()
        transport.stub("https://example.test/today/test/file.xml", body: "data")
        // Nothing can be created beneath /dev/null.
        let loader = makeLoader(transport, cacheDirectory: URL(fileURLWithPath: "/dev/null/chinook"))

        let response = try await loader.request(makeEndpoint(), strategy: .networkOnly)

        #expect(response.source == .network)
    }

    @Test func publicStorageHelpersUseTheSharedLoader() throws {
        let endpoint = makeEndpoint("/chinook-tests/\(UUID().uuidString)/file.xml")
        defer { try? FileManager.default.removeItem(at: endpoint.storageURL.deletingLastPathComponent()) }

        endpoint.cache(Data("shared".utf8))

        #expect(try Data(contentsOf: endpoint.storageURL) == Data("shared".utf8))
        #expect(endpoint.storageURL.path.hasSuffix("file.xml.cache"))
    }

    @Test func defaultCacheDirectoryIsUsable() {
        #expect(DataLoader.defaultCacheDirectory.isFileURL)
    }

    @Test func staticRequestUsesTheSharedLoader() async throws {
        let endpoint = makeEndpoint("/chinook-tests/\(UUID().uuidString)/static.xml")
        defer { try? FileManager.default.removeItem(at: endpoint.storageURL.deletingLastPathComponent()) }
        endpoint.cache(Data("static".utf8))

        let response = try await DataLoader.request(endpoint, strategy: .diskOnly)

        #expect(response.data == Data("static".utf8))
    }
}

/// Serves canned responses to a real `URLSession` so `URLSessionTransport` is exercised end to end.
final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data("stubbed".utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

@Suite struct URLSessionTransportTests {
    @Test func loadsThroughTheSession() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        let transport = URLSessionTransport(session: URLSession(configuration: configuration))

        let (data, response) = try await transport.data(from: URL(string: "https://example.test/x")!)

        #expect(data == Data("stubbed".utf8))
        #expect((response as? HTTPURLResponse)?.statusCode == 200)
    }

    @Test func defaultSessionIsConfiguredForReuseAndTimeouts() {
        let configuration = URLSessionTransport.makeSession().configuration

        #expect(configuration.timeoutIntervalForRequest == 30)
        #expect(configuration.httpMaximumConnectionsPerHost == 8)
    }

    @Test func defaultTransportCanBeConstructed() {
        _ = URLSessionTransport()
    }
}
