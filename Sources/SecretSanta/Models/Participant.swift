//
//  Participant.swift
//  SecretSanta
//
//  Created by caroletm on 09/12/2025.
//

import Vapor
import Fluent

final class Participant : Model, Content, @unchecked Sendable {
    static let schema = "Participant"
    
    @ID(key: .id) var id : UUID?
    @Field(key: "name") var name: String
    @Field(key: "email") var email: String
    @Field(key: "telephone") var telephone: String
    
    @OptionalParent(key: "user_id") var user: User?
    @Parent(key: "event_id") var event: Event
    
    @Children(for: \.$giver) var tiragesAsGiver: [Tirage]
    @Children(for: \.$receiver) var tiragesAsReceiver: [Tirage]
    
    @Children(for: \.$expediteur) var lettersSent: [Letter]
    @Children(for: \.$destinataire) var lettersReceived: [Letter]

    init() {}
    
    init(id: UUID? = nil, name: String, email: String, telephone: String, event_Id : Event.IDValue) {
        self.id = id ?? UUID()
        self.name = name
        self.email = email
        self.telephone = telephone
        self.$event.id = event_Id
    }
}

