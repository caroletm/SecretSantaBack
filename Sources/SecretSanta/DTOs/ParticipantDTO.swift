//
//  ParticipantDTO.swift
//  SecretSanta
//
//  Created by caroletm on 09/12/2025.
//

import Fluent
import Vapor

struct ParticipantCreateDTO: Content {
    var name: String
    var email: String
    var telephone: String
}

struct ParticipantDTO: Content {
    var id: UUID?
    var name: String
    var email: String
    var telephone: String
}

struct ParticipantJoinDTO : Content {
    var participantId: UUID
    var email: String
    var codeEvent: String
}

struct ParticipantJoinResponse: Content {
    let participantId: UUID
    let eventId: UUID
}

extension ParticipantCreateDTO {
    func validate(on req: Request) throws {
        
        // --- Nom obligatoire ---
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw Abort(.badRequest, reason: "Le nom du participant est obligatoire.")
        }
        
        // --- Email valide ---
        guard email.contains("@"),
              email.contains("."),
              email.count >= 5 else {
            throw Abort(.badRequest, reason: "L'email du participant n'est pas valide.")
        }
        
        // --- Téléphone : uniquement chiffres + 10 à 15 caractères ---
        let phoneRegex = #"^[0-9]{8,15}$"#
        let isValidPhone = email.range(of: phoneRegex, options: .regularExpression) != nil
        
        guard isValidPhone else {
            throw Abort(.badRequest, reason: "Le numéro de téléphone doit contenir uniquement des chiffres (8 à 15).")
        }
    }
}
