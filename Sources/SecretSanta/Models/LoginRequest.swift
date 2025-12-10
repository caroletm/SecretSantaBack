//
//  LoginRequest.swift
//  SecretSanta
//
//  Created by caroletm on 09/12/2025.
//

import Vapor

struct LoginRequest: Content {
    let email: String
    let password: String
}
