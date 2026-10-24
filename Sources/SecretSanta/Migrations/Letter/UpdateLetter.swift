//
//  UpdateLetter.swift
//  SecretSanta
//
//  Created by caroletm on 09/12/2025.
//

import Fluent

struct UpdateLetter: AsyncMigration {
    func prepare(on db: any Database) async throws {
        try await db.schema("letter")
            .field("expediteur_id", .uuid, .required,
                   .references("participant", "id"))
            .field("destinataire_id", .uuid, .required,
                   .references("participant", "id"))
            .update()
    }
    func revert(on db: any Database) async throws {
        try await db.schema("letter")
            .deleteField("expediteur_id")
            .deleteField("destinataire_id")
            .update()
    }
}
