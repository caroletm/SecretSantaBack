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
        letter.get("all", use: getAllLettersForAdmin)
        let protectedRoutes = letter.grouped(JWTMiddleware())
        
        protectedRoutes.post(use: createLetter)
        protectedRoutes.get(use: getAllLetters)
        
        protectedRoutes.group(":id") { letter in
            letter.delete(use: deleteLetter)
        }
    }
    
    //GET/letter/all
    @Sendable
    func getAllLettersForAdmin(_ req: Request) async throws -> [LetterDTO] {
        // Récupérer toutes les lettres dont il est le destinataire
        let letters = try await Letter.query(on: req.db)
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
    
    //GET/letter
    //Récupère tous les letters du user (filtré par son token)
    @Sendable
    func getAllLetters(_ req: Request) async throws -> [LetterDTO] {
        
        let payload = try req.auth.require(UserPayload.self)
        let userId = payload.id

        // Récupérer TOUS les participants de ce user
        let participants = try await Participant.query(on: req.db)
            .filter(\.$user.$id == userId)
            .all()
        
        let participantIds = try participants.map { try $0.requireID() }

        // Récupérer toutes les lettres pour tous ces participants
        let letters = try await Letter.query(on: req.db)
            .filter(\.$destinataire.$id ~~ participantIds)  // ← Opérateur IN
            .with(\.$expediteur)
            .with(\.$destinataire)
            .sort(\.$date, .descending)
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
//    @Sendable
//    func createLetter(_ req: Request) async throws -> LetterDTO {
//
//        let payload = try req.auth.require(UserPayload.self)
//        let userId = payload.id
//
//        let dto = try req.content.decode(LetterCreateDTO.self)
//
//
//        // Trouver le participant lié au user
//        guard let expediteur = try await Participant.query(on: req.db)
//            .filter(\.$user.$id == userId)
//            .filter(\.$event.$id == dto.eventId)   // 👈 essentiel !
//            .with(\.$event)
//            .first()
//        else {
//            throw Abort(.notFound, reason: "Aucun participant dans cet event pour cet utilisateur.")
//        }
//
//        let eventId = expediteur.$event.id
//
//        // Trouver le destinataire (notre pere noel du Secret Santa)
//        guard let tirage = try await Tirage.query(on: req.db)
//            .filter(\.$event.$id == eventId)
//            .filter(\.$receiver.$id == expediteur.requireID())
//            .with(\.$giver)
//            .first()
//        else {
//            throw Abort(.notFound, reason: "Aucun tirage trouvé pour cet utilisateur")
//        }
//
//        let destinataireId = tirage.$giver.id
//
//        // Créer la lettre
//        let letter = Letter(
//            message: dto.message,
//            signature: dto.signature,
//            typeLetter: dto.typeLetter,
//            expediteur_id: try expediteur.requireID(),
//            destinataire_id: destinataireId
//        )
//
//        try await letter.save(on: req.db)
//
//        return LetterDTO(
//            id: letter.id,
//            message: letter.message,
//            signature: letter.signature,
//            typeLetter: letter.typeLetter,
//            date: letter.date,
//            expediteur: letter.$expediteur.id,
//            destinataire: letter.$destinataire.id
//        )
//    }
    
    @Sendable
    func createLetter(_ req: Request) async throws -> LetterDTO {

        let payload = try req.auth.require(UserPayload.self)
        let userId = payload.id
        let dto = try req.content.decode(LetterCreateDTO.self)

        // Expéditeur
        guard let expediteur = try await Participant.query(on: req.db)
            .filter(\.$user.$id == userId)
            .filter(\.$event.$id == dto.eventId)
            .first()
        else {
            throw Abort(.notFound)
        }

        // Tirage (receiver → giver)
        guard let tirage = try await Tirage.query(on: req.db)
            .filter(\.$event.$id == dto.eventId)
            .filter(\.$receiver.$id == expediteur.requireID())
            .first()
        else {
            throw Abort(.notFound)
        }

        // GARDE-FOU EXPLICITE (important)
        let giver = try await tirage.$giver.get(on: req.db)
        guard giver.$event.id == dto.eventId else {
            throw Abort(
                .internalServerError,
                reason: "Tirage incohérent : giver hors event"
            )
        }

        // Création lettre
        let letter = Letter(
            message: dto.message,
            signature: dto.signature,
            typeLetter: dto.typeLetter,
            expediteur_id: try expediteur.requireID(),
            destinataire_id: try giver.requireID()
        )

        try await letter.save(on: req.db)

        // Mapping DTO explicite
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

