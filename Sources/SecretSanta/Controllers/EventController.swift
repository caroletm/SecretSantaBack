//
//  EventController.swift
//  SecretSanta
//
//  Created by caroletm on 09/12/2025.
//

import Vapor
import Fluent

struct EventController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let event = routes.grouped("event")
        
        let protectedRoutes = event.grouped(JWTMiddleware())
        protectedRoutes.get(use: getAllEvents)  // GET /event
        protectedRoutes.post(use: createEvent)
        
        protectedRoutes.group(":id") { eventId in
            eventId.get(use: getEventById)
            eventId.delete(use: deleteEventById)
        }
    }
    
    //GET/event
    //Récupère tous les events du user (filtré par son token)
    @Sendable
    func getAllEvents(_ req: Request) async throws -> [EventDTO] {
        
        let payload = try req.auth.require(UserPayload.self)
        let userId = payload.id
        
        let event = try await Event.query(on: req.db)
            .filter(\.$creator.$id == userId)
            .with(\.$participants)
            .with(\.$tirages)
            .all()
        
        return event.map { EventDTO(
            id: $0.id,
            nom: $0.nom,
            description: $0.description,
            image: $0.image,
            date: $0.date,
            lieu: $0.lieu,
            prixCadeau: $0.prixCadeau,
            codeEvent: $0.codeEvent,
            creatorId: userId,
            participants: $0.participants.map { p in
                ParticipantDTO(id: p.id, name: p.name, email: p.email, telephone: p.telephone)},
            tirages: $0.tirages.map {TirageDTO(giverId: $0.$giver.id, receiverId: $0.$receiver.id)}
        )}
    }
    
    //GET/event/id:
    //Récupère toutes les events du user (filtré par son token) filtré par l'ID de l'event
    @Sendable
    func getEventById(_ req: Request) async throws -> EventDTO {
        
        let payload = try req.auth.require(UserPayload.self)
        let userId = payload.id
        
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "ID invalide")
        }
        
        guard let event = try await Event.query(on: req.db)
            .filter(\.$id == id)
            .filter(\.$creator.$id == userId)
            .with(\.$participants)
            .with(\.$tirages)
            .first() else {
            throw Abort(.notFound)
        }
        return EventDTO(
            id: event.id,
            nom: event.nom,
            description: event.description,
            image: event.image,
            date: event.date,
            lieu: event.lieu,
            prixCadeau: event.prixCadeau,
            codeEvent: event.codeEvent,
            creatorId: userId,
            participants: event.participants.map { participant in
                ParticipantDTO(
                    id: participant.id,
                    name: participant.name,
                    email: participant.email,
                    telephone: participant.telephone
                )
            },
            tirages: event.tirages.map {
                TirageDTO(giverId: $0.$giver.id, receiverId: $0.$receiver.id)
            }
        )
    }

    @Sendable
    func createEvent(_ req: Request) async throws -> EventDTO {
        let payload = try req.auth.require(UserPayload.self)
        let userId = payload.id
        
        let dto = try req.content.decode(EventCreateDTO.self)
        try dto.validate(on: req)
        let codeEvent = String.randomSecretCode()
        
        //CREATION DE L EVENT
        let newEvent = Event(
            nom : dto.nom,
            description: dto.description,
            image: dto.image,
            date: dto.date,
            lieu: dto.lieu,
            prixCadeau: dto.prixCadeau,
            codeEvent: codeEvent,
            creator_Id: userId)
        
        try await newEvent.save(on: req.db)
        
        //CREATION DES PARTICIPANTS
        var participantList : [Participant] = []
        
        for participantDTO in dto.participants {
            try participantDTO.validate(on: req)
        }
        
        for p in dto.participants {
            let participant = Participant(
                name: p.name, email: p.email, telephone: p.telephone, event_Id: try newEvent.requireID())
            try await participant.save(on: req.db)
            participantList.append(participant)
        }
        
        //TIRAGE AU SORT
        let tirage = try await generateTirage(event: newEvent, participants: participantList, db: req.db)
        
        return EventDTO(
            id: try newEvent.requireID(),
            nom: newEvent.nom,
            description: newEvent.description,
            image: newEvent.image,
            date: newEvent.date,
            lieu: newEvent.lieu,
            prixCadeau: newEvent.prixCadeau,
            codeEvent: newEvent.codeEvent,
            creatorId: userId,
            participants: participantList.map {ParticipantDTO(id: $0.id!, name: $0.name, email: $0.email, telephone: $0.telephone)},
            tirages: tirage.map {TirageDTO(giverId: $0.$giver.id, receiverId: $0.$receiver.id)})
    }
    
    // MARK: - SECRET SANTA LOGIC
    private func generateTirage(event: Event, participants: [Participant], db: any Database) async throws -> [Tirage] {
        
        var shuffled = participants.shuffled()
        var result: [Tirage] = []
        
        for (index, p) in participants.enumerated() {
            var drawn = shuffled[index]
            
            if drawn.id == p.id {
                let next = (index + 1) % participants.count
                shuffled.swapAt(index, next)
                drawn = shuffled[index]
            }

            let t = Tirage(
                event_Id: try event.requireID(),
                giver_Id: try p.requireID(),
                receiver_Id: try drawn.requireID()
            )
            
            try await t.save(on: db)
            result.append(t)
        }

        return result
    }
    
    // DELETE /event/:id
    @Sendable
    func deleteEventById(_ req: Request) async throws -> HTTPStatus {
        let payload = try req.auth.require(UserPayload.self)
        let userId = payload.id

        guard let eventId = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "ID invalide")
        }

        // Vérifie que l’event appartient bien au user
        guard let event = try await Event.query(on: req.db)
            .filter(\.$id == eventId)
            .filter(\.$creator.$id == userId)
            .first()
        else {
            throw Abort(.notFound, reason: "Event introuvable ou non autorisé")
        }

        try await event.delete(on: req.db)

        return .noContent
    }
    
}

extension String {
    static func randomSecretCode(length: Int = 6) -> String {
        let chars = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
        return String((0..<length).map { _ in chars.randomElement()! })
    }
}
