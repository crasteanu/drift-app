import SwiftData

// MARK: - Versioned Schema

/// V1 is the initial shipped schema.
/// Add new VersionedSchema enums here for future model changes,
/// then add a migration stage to DriftMigrationPlan.
enum DriftSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [Dream.self, DreamSymbol.self] }
}

// MARK: - Migration Plan

/// Baseline migration plan — no stages needed yet.
/// When the model changes in a future release, add a lightweight or custom
/// MigrationStage here so existing user data survives the upgrade.
enum DriftMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [DriftSchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}
