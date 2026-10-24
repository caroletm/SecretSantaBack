//
//  UpdateEventText.swift
//  SecretSanta
//
//  Created by caroletm on 28/01/2026.
//
//
//import Fluent
//
//struct UpdateEventDescriptionToText: AsyncMigration {
//    func prepare(on db: any Database) async throws {
//        try await db.schema("Event")
//            .updateField("description", .sql(.text))
//            .update()
//    }
//
//    func revert(on db: any Database) async throws {
//        try await db.schema("Event")
//            .updateField("description", .string)
//            .update()
//    }
//}
//
