//
//  Letter.swift
//  SecretSanta
//
//  Created by caroletm on 09/12/2025.
//

import Vapor
import Fluent

final class Letter : Model, Content, @unchecked Sendable {
    static let schema = "Letter"
    
    @ID(key: .id) var id : UUID?
    @Field(key: "message") var message: String
    @Field(key: "signature") var signature: String
    @Field(key: "typeLetter") var typeLetter: TypeLetter
    @Timestamp(key: "date", on: .create) var date: Date?
    @Parent(key: "expediteur_id") var expediteur: Participant
    @Parent(key: "destinataire_id") var destinataire: Participant
    
    init() {
        self.id = UUID()
    }
    
    init(id: UUID? = nil, message: String, signature: String, typeLetter: TypeLetter, expediteur_id: Participant.IDValue, destinataire_id: Participant.IDValue) {
        self.id = id ?? UUID()
        self.message = message
        self.signature = signature
        self.typeLetter = typeLetter
        self.$expediteur.id = expediteur_id
        self.$destinataire.id = destinataire_id
    }
}
