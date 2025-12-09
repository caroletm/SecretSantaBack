//
//  UpdateParticipant.swift
//  SecretSanta
//
//  Created by caroletm on 09/12/2025.
//


import Fluent

struct UpdateParticipant: AsyncMigration {
    func prepare(on db: any Database) async throws {
        try await db.schema("Participant")
            .field("user_id", .uuid,
                         .references("users", "id", onDelete: .setNull))
            .field("event_id", .uuid, .required,
                   .references("Event", "id", onDelete: .cascade))
            .update()
    }
    func revert(on db: any Database) async throws {
        try await db.schema("Participant")
            .deleteField("user_id")
            .deleteField("event_id")
            .update()
    }
}
