//
//  UpdateEvent.swift
//  SecretSanta
//
//  Created by caroletm on 09/12/2025.
//


import Fluent

struct UpdateEvent: AsyncMigration {
    func prepare(on db: any Database) async throws {
        try await db.schema("Event")
            .field("creator_id", .uuid, .required,
                .references("users", "id", onDelete: .cascade))
            .update()
    }
    func revert(on db: any Database) async throws {
        try await db.schema("Event")
            .deleteField("user_id")
            .update()
    }
}
