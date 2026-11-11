import Domain
import Foundation
import SwiftData

/// The on-device store: one SwiftData container, the actor that owns it, and the change
/// broadcaster the repositories observe. Built once by the app's composition root.
public final class LittleStore: Sendable {
    let actor: LittleStoreActor
    let changes = ChangeBroadcaster()

    /// - Parameter inMemory: true for tests and previews; nothing is written to disk.
    public init(inMemory: Bool = false) throws {
        let schema = Schema(versionedSchema: LittleStorySchemaV1.self)
        // A unique name per in-memory store keeps parallel tests from sharing data.
        let configuration = inMemory
            ? ModelConfiguration(UUID().uuidString, schema: schema, isStoredInMemoryOnly: true)
            : ModelConfiguration(schema: schema)
        let container = try ModelContainer(
            for: schema,
            migrationPlan: LittleStoryMigrationPlan.self,
            configurations: [configuration],
        )
        actor = LittleStoreActor(modelContainer: container)
    }

    func observe<Value: Sendable & Equatable>(
        _ table: StoreTable,
        fetch: @escaping @Sendable (LittleStoreActor) async -> Value,
    ) -> AsyncStream<Value> {
        let actor = actor
        return changes.observe([table]) { await fetch(actor) }
    }

    /// Runs `body` on the store, then tells observers of `tables` to read again.
    @discardableResult
    func write<Output: Sendable>(
        _ tables: StoreTable...,
        body: @Sendable (LittleStoreActor) async -> Output,
    ) async -> Output {
        await write(tables: Set(tables), body: body)
    }

    @discardableResult
    func write<Output: Sendable>(
        tables: Set<StoreTable>,
        body: @Sendable (LittleStoreActor) async -> Output,
    ) async -> Output {
        let result = await body(actor)
        changes.publish(tables)
        return result
    }
}
