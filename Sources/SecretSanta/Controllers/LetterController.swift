//
//  LetterController.swift
//  SecretSanta
//
//  Created by caroletm on 09/12/2025.
//

import Vapor
import Fluent

struct LetterController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let letter = routes.grouped("letter")
        let protectedRoutes = letter.grouped(JWTMiddleware())
        
        protectedRoutes.post(use: createLetter)
        
        protectedRoutes.get("event", ":eventId", use: getLettersByEvent)
        
        protectedRoutes.get("participant", ":participantId", use: getLettersByParticipant)
        
        protectedRoutes.group(":id") { letter in
            letter.delete(use: deleteLetter)
        }
    }
    
//    POST/letter
    @Sendable
    func createLetter(_ req: Request) async throws -> LetterDTO {
        
        let dto = try req.content.decode(LetterCreateDTO.self)
        
        guard let expediteur = try await Participant.find(dto.expediteurId, on: req.db) else {
            throw Abort(.notFound, reason : "Expediteur introuvable")
        }
        
        guard let destinataire = try await Participant.find(dto.destinataireId, on: req.db) else {
            throw Abort(.notFound, reason: "Destinataire introuvable")
        }
        
        let letter = Letter(
            message: dto.message,
            signature: dto.signature,
            typeLetter: .fromUserToFriend,
            expediteur_id: try expediteur.requireID(),
            destinataire_id: try destinataire.requireID()
        )
        try await letter.save(on: req.db)
        
        return LetterDTO(
            id: letter.id,
            message: letter.message,
            signature: letter.signature,
            typeLetter: letter.typeLetter,
            date: letter.date,
            expediteur: letter.$expediteur.id,
            destinataire: letter.$destinataire.id
        )
    }
    
    //GET/letter/event/:eventid
    @Sendable
    func getLettersByEvent(_ req: Request) async throws -> [LetterDTO] {
        guard let eventId = req.parameters.get("eventId", as: UUID.self) else {
            throw Abort(.badRequest)
        }

        let letters = try await Letter.query(on: req.db)
            .join(parent: \.$expediteur)
            .filter(Participant.self, \.$event.$id == eventId)
            .with(\.$expediteur)
            .with(\.$destinataire)
            .all()

        return letters.map { letter in
            LetterDTO(
                id: letter.id,
                message: letter.message,
                signature: letter.signature,
                typeLetter: letter.typeLetter,
                date: letter.date,
                expediteur: letter.$expediteur.id,
                destinataire: letter.$destinataire.id
            )
        }
    }
    
//    GET /letter/participant/:participantId
    @Sendable
    func getLettersByParticipant(_ req: Request) async throws -> [LetterDTO] {
        guard let participantId = req.parameters.get("participantId", as: UUID.self) else {
            throw Abort(.badRequest)
        }

        let letters = try await Letter.query(on: req.db)
            .filter(\.$destinataire.$id == participantId)
            .with(\.$expediteur)
            .with(\.$destinataire)
            .all()

        return letters.map { letter in
            LetterDTO(
                id: letter.id,
                message: letter.message,
                signature: letter.signature,
                typeLetter: letter.typeLetter,
                date: letter.date,
                expediteur: letter.$expediteur.id,
                destinataire: letter.$destinataire.id
            )
        }
    }
    
//    DELETE /letter/:id
    @Sendable
    func deleteLetter(_ req: Request) async throws -> HTTPStatus {
        guard let id = req.parameters.get("id", as: UUID.self),
              let letter = try await Letter.find(id, on: req.db)
        else {
            throw Abort(.notFound)
        }

        try await letter.delete(on: req.db)
        return .noContent
    }
    
}

