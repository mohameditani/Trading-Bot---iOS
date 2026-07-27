import Foundation
import Testing
@testable import BotDataKit

@Test func bundledProviderReturnsThePayloadItIsGiven() async throws {
    let provider = BundledSnapshotProvider(loader: { Fixtures.full })
    let payload = try await provider.fetchPayload()
    let snapshot = try SnapshotDecoder.decode(payload)
    #expect(snapshot.summary.total == 28)
    #expect(snapshot.hasReviewLayer)
}

@Test func bundledProviderSurfacesAMissingResource() async {
    let provider = BundledSnapshotProvider(resource: "does-not-exist", loader: { nil })
    await #expect(throws: SnapshotError.resourceMissing("does-not-exist")) {
        _ = try await provider.fetchPayload()
    }
}

@Test func bundledProviderIsIndifferentToPayloadValidity() async throws {
    // The provider only transports bytes; decoding failures surface in the repository.
    let provider = BundledSnapshotProvider(loader: { Fixtures.malformed })
    let payload = try await provider.fetchPayload()
    #expect(payload == Fixtures.malformed)
}

@Test func bundledProviderCanServeTheAINullFixture() async throws {
    let provider = BundledSnapshotProvider(loader: { Fixtures.aiNull })
    let snapshot = try SnapshotDecoder.decode(try await provider.fetchPayload())
    #expect(snapshot.hasReviewLayer == false)
}
