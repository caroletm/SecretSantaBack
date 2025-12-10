//
//  Event.swift
//  SecretSanta
//
//  Created by caroletm on 09/12/2025.
//

import Vapor
import Fluent

final class Event : Model, Content, @unchecked Sendable {
    static let schema = "Event"
    
    @ID(key: .id) var id : UUID?
    @Field(key: "nom") var nom: String
    @Field(key: "description") var description: String
    @Field(key: "image") var image: String
    @Field(key: "date") var date: Date
    @Field(key: "lieu") var lieu: String
    @Field(key: "prixCadeau") var prixCadeau: Int
    @Field(key: "codeEvent") var codeEvent: String
    @Parent(key: "creator_Id") var creator: User
    @Children(for : \.$event) var participants: [Participant]
    @Children(for : \.$event) var tirages: [Tirage]
    
    init() {
        self.id = UUID()
    }
    
    init(id: UUID? = nil, nom: String, description: String, image: String, date: Date, lieu: String, prixCadeau: Int, codeEvent: String, creator_Id: IDValue) {
   
        self.id = id ?? UUID()
        self.nom = nom
        self.description = description
        self.image = image
        self.date = date
        self.lieu = lieu
        self.prixCadeau = prixCadeau
        self.codeEvent = codeEvent
        self.$creator.id = creator_Id
    }
}
