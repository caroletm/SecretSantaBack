//
//  User.swift
//  SecretSanta
//
//  Created by caroletm on 09/12/2025.
//


import Vapor
import Fluent

final class User : Model, Content, @unchecked Sendable {
    static let schema = "users"
    
    @ID(key: .id) var id : UUID?
    @Field(key: "name") var name: String
    @Field(key: "email") var email: String
    @Field(key: "password") var password: String
    @Field(key: "telephone") var telephone: String
    @Children(for : \.$user) var participant: [Participant]
    
    init() {
        self.id = UUID()
    }
    
    init(id: UUID? = nil, name: String, email: String, password: String, telephone: String) {
        self.id = id ?? UUID()
        self.name = name
        self.email = email
        self.password = password
        self.telephone = telephone
    }
}

