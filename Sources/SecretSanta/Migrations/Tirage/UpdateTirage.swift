//
//  UpdateTirage.swift
//  SecretSanta
//
//  Created by caroletm on 09/12/2025.
//

import Fluent

struct UpdateTirage: AsyncMigration {
    func prepare(on db: any Database) async throws {
        try await db.schema("Tirage")
            .field("giver_id", .uuid, .required,
                .references("Participant", "id", onDelete: .cascade))
            .field("receiver_id", .uuid, .required,
                .references("Participant", "id", onDelete: .cascade))
            .update()
    }
    func revert(on db: any Database) async throws {
        try await db.schema("Tirage")
            .deleteField("giver_id")
            .deleteField("receiver_id")
            .update()
    }
}

struct UpdateTirageEvent: AsyncMigration {
    func prepare(on db: any Database) async throws {
        try await db.schema("Tirage")
            .field("event_id", .uuid, .required,
                   .references("Event", "id", onDelete: .cascade))
            .update()
    }
        func revert(on db: any Database) async throws {
            try await db.schema("Tirage")
                .deleteField("event_id")
                .update()
    }
}
