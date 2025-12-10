//
//  UserDTO.swift
//  SecretSanta
//
//  Created by caroletm on 09/12/2025.
//

import Vapor

struct UserCreateDTO: Content {
    var name: String
    var email: String
    var password: String
    var telephone: String
}

struct UserDTO: Content {
    var id: UUID?
    var name: String
    var email: String
    var telephone: String
}

struct UserUpdateDTO: Content {
    var name: String?
    var email: String?
    var password: String?
    var telephone: String?
}

