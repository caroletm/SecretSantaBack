//
//  EventDTO.swift
//  SecretSanta
//
//  Created by caroletm on 09/12/2025.
//

import Vapor


struct EventCreateDTO: Content {
    var nom: String
    var description: String
    var image: String
    var date: Date
    var lieu: String
    var prixCadeau: Int
    var participants: [ParticipantCreateDTO]
}

struct EventDTO: Content {
    var id: UUID?
    var nom: String
    var description: String
    var image: String
    var date: Date
    var lieu: String
    var prixCadeau: Int
    var codeEvent: String
    var creatorId: UUID
    var participants: [ParticipantDTO]
    var tirages: [TirageDTO]
}

struct UpdateEventDTO: Content {
    var nom: String?
    var description: String?
    var image: String?
    var date: Date?
    var lieu: String?
    var prixCadeau: Int?
    var codeEvent: String?
}

extension EventCreateDTO {
    func validate(on req: Request) throws {
        
        guard !nom.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw Abort(.badRequest, reason: "Le nom de l'évènement est obligatoire.")
        }
        
        guard !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw Abort(.badRequest, reason: "La description de l'évènement est obligatoire.")
        }
        
        guard date > Date() else {
            throw Abort(.badRequest, reason: "La date de l'évènement doit être dans le futur.")
        }
        
        guard prixCadeau >= 0 else {
            throw Abort(.badRequest, reason: "Le prix du cadeau doit être positif.")
        }
        
        guard !image.isEmpty else {
            throw Abort(.badRequest, reason: "Une image d'évènement est obligatoire.")
        }
    }
}
