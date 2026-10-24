//
//  UpdateLetterCascade.swift
//  SecretSanta
//
//  Created by caroletm on 24/10/2026.
//

import Vapor
import Fluent
import FluentSQL

struct UpdateLetterCascade: AsyncMigration {
    func prepare(on db: any Database) async throws {
        guard let sql = db as? any SQLDatabase else {
            throw Abort(.internalServerError, reason: "UpdateLetterCascade nécessite une base SQL")
        }

        // Les noms des clés étrangères sont générés par Fluent (hash) et changent d'une base à l'autre :
        // on les lit dans information_schema au lieu de les écrire en dur
        let rows = try await sql.raw("""
            SELECT CONSTRAINT_NAME AS name FROM information_schema.KEY_COLUMN_USAGE
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'letter' AND REFERENCED_TABLE_NAME IS NOT NULL
            """).all()

        for row in rows {
            let name = try row.decode(column: "name", as: String.self)
            try await sql.raw("ALTER TABLE letter DROP FOREIGN KEY \(ident: name)").run()
        }

        try await sql.raw("""
            ALTER TABLE letter
            ADD CONSTRAINT fk_letter_expediteur FOREIGN KEY (expediteur_id) REFERENCES participant (id) ON DELETE CASCADE,
            ADD CONSTRAINT fk_letter_destinataire FOREIGN KEY (destinataire_id) REFERENCES participant (id) ON DELETE CASCADE
            """).run()
    }

    func revert(on db: any Database) async throws {
        guard let sql = db as? any SQLDatabase else {
            throw Abort(.internalServerError, reason: "UpdateLetterCascade nécessite une base SQL")
        }

        try await sql.raw("""
            ALTER TABLE letter
            DROP FOREIGN KEY fk_letter_expediteur,
            DROP FOREIGN KEY fk_letter_destinataire
            """).run()

        try await sql.raw("""
            ALTER TABLE letter
            ADD CONSTRAINT fk_letter_expediteur FOREIGN KEY (expediteur_id) REFERENCES participant (id),
            ADD CONSTRAINT fk_letter_destinataire FOREIGN KEY (destinataire_id) REFERENCES participant (id)
            """).run()
    }
}
