//
//  UpdateTirage.swift
//  SecretSanta
//
//  Created by caroletm on 09/12/2025.
//

import Fluent

struct UpdateTirage: AsyncMigration {
    func prepare(on db: any Database) async throws {
        try await db.schema("tirage")
            .field("giver_id", .uuid, .required,
                .references("participant", "id", onDelete: .cascade))
            .field("receiver_id", .uuid, .required,
                .references("participant", "id", onDelete: .cascade))
            .update()
    }
    func revert(on db: any Database) async throws {
        try await db.schema("tirage")
            .deleteField("giver_id")
            .deleteField("receiver_id")
            .update()
    }
}

struct UpdateTirageEvent: AsyncMigration {
    func prepare(on db: any Database) async throws {
        try await db.schema("tirage")
            .field("event_id", .uuid, .required,
                   .references("event", "id", onDelete: .cascade))
            .update()
    }
        func revert(on db: any Database) async throws {
            try await db.schema("tirage")
                .deleteField("event_id")
                .update()
    }
}
