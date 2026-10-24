//
//  UpdateLetterText.swift
//  SecretSanta
//
//  Created by caroletm on 28/01/2026.
//

import Fluent

struct UpdateLetterMessageToText: AsyncMigration {
    func prepare(on db: any Database) async throws {
        try await db.schema("letter")
            .updateField("message", .sql(.text))
            .update()
    }

    func revert(on db: any Database) async throws {
        try await db.schema("letter")
            .updateField("message", .string)
            .update()
    }
}
