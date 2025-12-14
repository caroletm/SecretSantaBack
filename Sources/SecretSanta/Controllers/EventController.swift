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
            
            // /event/:id/draw
            eventId.group("draw") { group in
                group.get(use: getDrawForUser)   // GET /event/:id/draw
            }
        }
    }
    
    //GET/event
    //Récupère tous les events du user (filtré par son token)
    @Sendable
    func getAllEvents(_ req: Request) async throws -> [EventDTO] {

        let payload = try req.auth.require(UserPayload.self)
        let userId = payload.id

        // Récupérer les events créés par l'utilisateur
        let createdEvents = try await Event.query(on: req.db)
            .filter(\.$creator.$id == userId)
            .with(\.$participants)
            .with(\.$tirages)
            .all()

        // Récupérer les events où il est inscrit comme participant
        let participantEvents = try await Event.query(on: req.db)
            .join(Participant.self, on: \Participant.$event.$id == \Event.$id)
            .filter(Participant.self, \.$user.$id == userId)   // user est participant
            .with(\.$participants)
            .with(\.$tirages)
            .all()

        // Fusionner sans doublons
        let all = uniqueEvents(createdEvents + participantEvents)

        return all.map { event in
            EventDTO(
                id: event.id,
                nom: event.nom,
                description: event.description,
                image: event.image,
                date: event.date,
                lieu: event.lieu,
                prixCadeau: event.prixCadeau,
                codeEvent: event.codeEvent,
                creatorId: event.$creator.id,
                participants: event.participants.map {
                    ParticipantDTO(id: $0.id, name: $0.name, email: $0.email, telephone: $0.telephone)
                },
                tirages: event.tirages.map {
                    TirageDTO(giverId: $0.$giver.id, receiverId: $0.$receiver.id)
                }
            )
        }
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

    //POST/event
    @Sendable
    func createEvent(_ req: Request) async throws -> EventDTO {
        let payload = try req.auth.require(UserPayload.self)
        let userId = payload.id
        
        // 👉 Récupérer l'utilisateur pour obtenir son email
          guard let user = try await User.find(userId, on: req.db) else {
              throw Abort(.notFound, reason: "Utilisateur introuvable")
          }
          let creatorEmail = user.email.lowercased()
        
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
            
            // 👉 si email du participant == celui du créateur
                  if p.email.lowercased() == creatorEmail {
                      participant.$user.id = userId
                  }
            
            try await participant.save(on: req.db)
            participantList.append(participant)
        }
        
        //TIRAGE AU SORT
        let tirage = try await generateTirage(event: newEvent, participants: participantList, db: req.db)
        
        // ENVOI DES EMAILS
        for participant in participantList {
            let html = """
            <h2>🎁 Invitation Secret Santa\n</h2>
            <p>Bonjour <strong>\(participant.name)</strong>,</p>
            <p>Tu as été invité.e à participer au Secret Santa :</p>
            <p><strong>\(newEvent.nom)</strong></p>
            <p>Voici ton code pour rejoindre l’évènement :</p>
            <h3 style="color:#d40000;">\(newEvent.codeEvent)</h3>
            <p>🎄 Installe l'application avec cette adresse mail et entre ce code pour participer.</p>
            """

            try await BrevoEmailService.sendEmail(
                req: req,
                to: participant.email,
                subject: "🎅 Invitation au Secret Santa : \(newEvent.nom)",
                html: html
            )
        }
        
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
    
    
    
    // MARK: - SECRET SANTA TIRAGE LOGIC
    private func generateTirage(event: Event, participants: [Participant], db: any Database) async throws -> [Tirage] {

        var receivers = participants

        // On mélange jusqu'à obtenir un tirage valide
        repeat {
            receivers.shuffle()
        } while zip(participants, receivers).contains(where: { $0.id == $1.id })

        // Maintenant on a une permutation valide sans doublons et sans self-match
        var result: [Tirage] = []

        for (giver, receiver) in zip(participants, receivers) {
            let t = Tirage(
                event_Id: try event.requireID(),
                giver_Id: try giver.requireID(),
                receiver_Id: try receiver.requireID()
            )
            try await t.save(on: db)
            result.append(t)
        }

        return result
    }
    
    // GET /event/:eventId/draw/
    func getDrawForUser(_ req: Request) async throws -> DrawResultDTO {
        
        let payload = try req.auth.require(UserPayload.self)
        let userId = payload.id
        
        guard let eventId = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "eventId manquant")
        }
        
        // 1. Trouver le participant lié à ce user dans cet event
        guard let participant = try await Participant.query(on: req.db)
            .filter(\.$user.$id == userId)
            .filter(\.$event.$id == eventId)
            .first()
        else {
            throw Abort(.notFound, reason: "Aucun participant lié à ce user dans cet event")
        }

        // 2. Trouver son tirage (giverId)
        guard let tirage = try await Tirage.query(on: req.db)
            .filter(\.$event.$id == eventId)
            .filter(\.$giver.$id == participant.requireID())
            .with(\.$receiver)
            .first()
        else {
            throw Abort(.notFound, reason: "Aucun tirage trouvé pour ce participant")
        }

        return DrawResultDTO(
            giverId: try participant.requireID(),
            receiverId: tirage.$receiver.id,
            receiverName: tirage.receiver.name
        )
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

func uniqueEvents(_ events: [Event]) -> [Event] {
    var seen = Set<UUID>()
    var result: [Event] = []

    for e in events {
        if let id = e.id, !seen.contains(id) {
            seen.insert(id)
            result.append(e)
        }
    }
    return result
}
