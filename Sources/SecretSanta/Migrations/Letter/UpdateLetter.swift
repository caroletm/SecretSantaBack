//
//  UpdateLetter.swift
//  SecretSanta
//
//  Created by caroletm on 09/12/2025.
//

import Fluent

struct UpdateLetter: AsyncMigration {
    func prepare(on db: any Database) async throws {
        try await db.schema("Letter")
            .field("expediteur_id", .uuid, .required,
                   .references("Participant", "id"))
            .field("destinataire_id", .uuid, .required,
                   .references("Participant", "id"))
            .update()
    }
    func revert(on db: any Database) async throws {
        try await db.schema("Letter")
            .deleteField("expediteur_id")
            .deleteField("destinataire_id")
            .update()
    }
}
