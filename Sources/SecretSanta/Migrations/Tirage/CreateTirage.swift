//
//  CreateTirage.swift
//  SecretSanta
//
//  Created by caroletm on 09/12/2025.
//

import Fluent

struct CreateTirage: AsyncMigration {
    func prepare(on db: any Database) async throws {

        try await db.schema("tirage")
            .id()
            .create()
    }
    func revert(on db: any Database) async throws {
        try await db.schema("tirage").delete()
    }
}
