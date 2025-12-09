//
//  CreateLetter.swift
//  SecretSanta
//
//  Created by caroletm on 09/12/2025.
//

import Fluent

struct CreateLetter: AsyncMigration {
    func prepare(on db: any Database) async throws {
        
        let typeLetter = try await db.enum("typeLetter")
            .case("fromUserToFriend")
            .case("fromFriendToUser")
            .create()
        
        try await db.schema("Letter")
            .id()
            .field("message", .string, .required)
            .field("signature", .string, .required)
            .field("email", .string, .required)
            .field("typeLetter", typeLetter, .required)
            .field("date", .datetime)
            .create()
    }
    func revert(on db: any Database) async throws {
        try await db.schema("Letter").delete()
        try await db.enum("typeLetter").delete()
    }
}
