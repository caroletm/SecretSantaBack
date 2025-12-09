//
//  CreateEvent.swift
//  SecretSanta
//
//  Created by caroletm on 09/12/2025.
//

import Fluent

struct CreateEvent: AsyncMigration {
    func prepare(on db: any Database) async throws {
        
        try await db.schema("Event")
            .id()
            .field("nom", .string, .required)
            .field("description", .string, .required)
            .field("image", .string, .required)
            .field("date", .datetime, .required)
            .field("lieu", .string, .required)
            .field("prixCadeau", .int, .required)
            .field("codeEvent", .string, .required)
            .create()
    }
    func revert(on db: any Database) async throws {
        try await db.schema("Event").delete()
    }
}
