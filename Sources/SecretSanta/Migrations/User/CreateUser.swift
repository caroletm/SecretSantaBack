//
//  CreateUser.swift
//  SecretSanta
//
//  Created by caroletm on 09/12/2025.
//

import Fluent

struct CreateUser: AsyncMigration {
    func prepare(on db: any Database) async throws {
        
        try await db.schema("users")
            .id()
            .field("name", .string, .required)
            .field("email", .string, .required)
            .field("password", .string, .required)
            .field("telephone", .string, .required)
            .unique(on: "email")
            .create()
    }
    func revert(on db: any Database) async throws {
        try await db.schema("users").delete()
    }
}
