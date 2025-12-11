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
        protectedRoutes.get(use: getAllLetters)
        
        protectedRoutes.get("event", ":eventId", use: getLettersByEvent)
        protectedRoutes.get("participant", ":participantId", use: getLettersByParticipant)
        
        protectedRoutes.group(":id") { letter in
            letter.delete(use: deleteLetter)
        }
    }
    
    //GET/letter
    //Récupère tous les letters du user (filtré par son token)
    @Sendable
    func getAllLetters(_ req: Request) async throws -> [LetterDTO] {
        
        let payload = try req.auth.require(UserPayload.self)
        let userId = payload.id

        // Trouver le participant associé à ce user
        guard let participant = try await Participant.query(on: req.db)
            .filter(\.$user.$id == userId)
            .first()
        else {
            throw Abort(.notFound, reason: "Aucun participant associé à cet utilisateur.")
        }

        // Récupérer toutes les lettres dont il est le destinataire
        let letters = try await Letter.query(on: req.db)
            .filter(\.$destinataire.$id == participant.requireID())
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

//    POST/letter
    @Sendable
    func createLetter(_ req: Request) async throws -> LetterDTO {

        let payload = try req.auth.require(UserPayload.self)
        let userId = payload.id

        let dto = try req.content.decode(LetterCreateDTO.self)


        // Trouver le participant lié au user
        guard let expediteur = try await Participant.query(on: req.db)
            .filter(\.$user.$id == userId)
            .filter(\.$event.$id == dto.eventId)   // 👈 essentiel !
            .with(\.$event)
            .first()
        else {
            throw Abort(.notFound, reason: "Aucun participant dans cet event pour cet utilisateur.")
        }

        let eventId = expediteur.$event.id

        // Trouver le destinataire (tirage du Secret Santa)
        guard let tirage = try await Tirage.query(on: req.db)
            .filter(\.$event.$id == eventId)
            .filter(\.$giver.$id == expediteur.requireID())
            .with(\.$receiver)
            .first()
        else {
            throw Abort(.notFound, reason: "Aucun tirage trouvé pour cet utilisateur")
        }

        let destinataireId = tirage.$receiver.id

        // Créer la lettre
        let letter = Letter(
            message: dto.message,
            signature: dto.signature,
            typeLetter: dto.typeLetter,
            expediteur_id: try expediteur.requireID(),
            destinataire_id: destinataireId
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

