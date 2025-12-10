//
//  Tirage.swift
//  SecretSanta
//
//  Created by caroletm on 09/12/2025.
//

import Vapor
import Fluent

final class Tirage : Model, Content, @unchecked Sendable {
    static let schema = "Tirage"
    
    @ID(key: .id) var id : UUID?
    @Parent(key: "event_Id") var event: Event
    @Parent(key: "giver_Id") var giver: Participant
    @Parent(key: "receiver_Id") var receiver: Participant
    
    init() {
        self.id = UUID()
    }
    
    init(id: UUID? = nil, event_Id: Event.IDValue, giver_Id: Participant.IDValue, receiver_Id: Participant.IDValue) {
        self.id = id ?? UUID()
        self.$event.id = event_Id
        self.$giver.id = giver_Id
        self.$receiver.id = receiver_Id
    }
}
