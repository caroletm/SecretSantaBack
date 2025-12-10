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
    @Sendable
    func joinEvent(_ req: Request) async throws -> ParticipantJoinResponse {
        let payload = try req.auth.require(UserPayload.self)
        let userId = payload.id

        let dto = try req.content.decode(ParticipantJoinDTO.self)

        // Trouver l’event via code
        guard let event = try await Event.query(on: req.db)
            .filter(\.$codeEvent == dto.codeEvent)
            .first()
        else {
            throw Abort(.notFound, reason: "Aucun événement avec ce code.")
        }

        //  Trouver le participant
        guard let participant = try await Participant.query(on: req.db)
            .filter(\.$id == dto.participantId)
            .filter(\.$email == dto.email)
            .filter(\.$event.$id == event.id!)
            .first()
        else {
            throw Abort(.notFound, reason: "Participant non trouvé pour cet event.")
        }

        // Vérifier s’il est déjà lié
        if participant.$user.id != nil {
            throw Abort(.badRequest, reason: "Ce participant a déjà un compte associé.")
        }

        // Associer l'utilisateur au participant
        participant.$user.id = userId
        try await participant.save(on: req.db)

        return ParticipantJoinResponse(participantId: try participant.requireID(),
                                       eventId: try event.requireID())
    }
}
