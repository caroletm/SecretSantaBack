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
    @Parent(key: "event_id") var event: Event
    @Parent(key: "giver_id") var giver: Participant
    @Parent(key: "receiver_id") var receiver: Participant
    
    init() {
        self.id = UUID()
    }
    
    init(id: UUID? = nil, giver_id: Participant.IDValue, receiver_id: Participant.IDValue) {
        self.id = id ?? UUID()
        self.$giver.id = giver_id
        self.$receiver.id = receiver_id
    }
}
