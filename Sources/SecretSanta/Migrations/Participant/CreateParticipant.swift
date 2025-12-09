//
//  CreateParticipant.swift
//  SecretSanta
//
//  Created by caroletm on 09/12/2025.
//

import Fluent

struct CreateParticipant: AsyncMigration {
    func prepare(on db: any Database) async throws {
        
        try await db.schema("Participant")
            .id()
            .field("name", .string, .required)
            .field("email", .string, .required)
            .field("telephone", .string, .required)
            .create()
    }
    func revert(on db: any Database) async throws {
        try await db.schema("Participant").delete()
    }
}
