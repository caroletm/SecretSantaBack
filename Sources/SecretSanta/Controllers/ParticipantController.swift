//
//  ParticipantController.swift
//  SecretSanta
//
//  Created by caroletm on 10/12/2025.
//

import Vapor
import Fluent

struct ParticipantController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let participant = routes.grouped("participant")
        let protected = participant.grouped(JWTMiddleware())

        protected.post("join", use: joinEvent)
    }

    // POST /participant/join
    func joinEvent(_ req: Request) async throws -> ParticipantJoinResponse {
        let payload = try req.auth.require(UserPayload.self)
        let userId = payload.id

        let dto = try req.content.decode(ParticipantJoinDTO.self)   // juste le code

        // L'email vient du compte connecté, jamais de l'app : sinon on pourrait prendre la place d'un autre
        guard let user = try await User.find(userId, on: req.db) else {
            throw Abort(.notFound, reason: "Utilisateur introuvable")
        }

        // Trouver l’event via code
        let codeEvent = dto.codeEvent.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard let event = try await Event.query(on: req.db)
            .filter(\.$codeEvent == codeEvent)
            .first()
        else {
            throw Abort(.notFound, reason: "Aucun événement avec ce code.")
        }

        // Trouver le participant avec l'email du compte
        guard let participant = try await Participant.query(on: req.db)
            .filter(\.$event.$id == event.requireID())
            .filter(\.$email == user.email)
            .first()
        else {
            throw Abort(.notFound, reason: "Aucune invitation pour l'email de ton compte dans cet évènement.")
        }

        // Vérifier s’il est déjà lié
        if participant.$user.id != nil {
            throw Abort(.badRequest, reason: "Ce participant a déjà un compte associé.")
        }

        // Associer l'utilisateur
        participant.$user.id = userId
        try await participant.save(on: req.db)

        return ParticipantJoinResponse(
            participantId: try participant.requireID(),
            eventId: try event.requireID()
        )
    }}
