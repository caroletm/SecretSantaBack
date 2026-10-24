//
//  UserController.swift
//  SecretSanta
//
//  Created by caroletm on 09/12/2025.
//

import Vapor
import Fluent
import JWT

struct UserController : RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let users = routes.grouped("users")

        users.post(use: createUser)
        users.post("login", use: login)

        let protected = users.grouped(JWTMiddleware())
        protected.get("profile", use: profile)
        protected.delete("me", use: deleteMe)
    }
    
    // POST /users
    // Création d’un nouveau compte utilisateur.
    // Vérifie :
    //   - Email non déjà utilisé
    //   - Mot de passe ≥ 8 caractères
    @Sendable
    func createUser(_ req: Request) async throws -> UserDTO {
        let dto = try req.content.decode(UserCreateDTO.self)
        let email = dto.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if try await User.query(on: req.db)
            .filter(\.$email == email)
            .first() != nil {
            throw Abort(.badRequest, reason: "Un utilisateur avec cet email existe déjà")
        }

        if dto.password.count < 8 {
            throw Abort(.badRequest, reason: "Le mot de passe doit contenir au moins 8 caractères.")
        }
        let passwordHashed = try Bcrypt.hash(dto.password)

        let user = User(
            name: dto.name,
            email: email,
            password: passwordHashed,
            telephone: dto.telephone,
        )
        
        try await user.save(on: req.db)
        
        return UserDTO(
            id: user.id,
            name : user.name,
            email: user.email,
            telephone: user.telephone
        )
    }
    
    // POST /users/login
    // Authentifie un utilisateur.
    // Vérifie :
    //   - Email existe
    //   - Mot de passe valide
    //
    // Retour :
    //   { "token": "JWT_TOKEN" }
    struct LoginResponse: Content {
        let token: String
    }
    
    @Sendable
    func login(req: Request) async throws -> LoginResponse {
        let userData = try req.content.decode(LoginRequest.self)
        let email = userData.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard let user = try await User.query(on: req.db)
            .filter(\.$email == email)
            .first(),
              try Bcrypt.verify(userData.password, created: user.password) else {
            throw Abort(.unauthorized, reason: "Email ou mot de passe incorrect")
        }
        
        let payload = UserPayload(id: try user.requireID())
        
        guard let secret = Environment.get("JWT_SECRET") else {
            fatalError("JWT_SECRET manquant")
        }

        let signer = JWTSigner.hs256(key: secret)
        
        let token = try signer.sign(payload)
        return LoginResponse(token:token)
    }
    
    // GET /users/profile
       //Protégé par JWT
       // Retourne le profil de l’utilisateur connecté.
       //
       // Retour : UserDTO
    @Sendable
    func profile(req: Request) async throws -> UserDTO {
        let payload = try req.auth.require(UserPayload.self)
        guard let user = try await User.find(payload.id, on: req.db) else {
            throw Abort(.notFound)
        }
        return UserDTO(
            id: user.id,
            name : user.name,
            email: user.email,
            telephone: user.telephone
        )
    }
    // DELETE /users/me
    // Protégé par JWT
    // Supprime le compte de l'utilisateur connecté.
    //
    // Retour : 204 No Content
    @Sendable
    func deleteMe(_ req: Request) async throws -> HTTPStatus {
        let payload = try req.auth.require(UserPayload.self)
        guard let user = try await User.find(payload.id, on: req.db) else {
            throw Abort(.notFound)
        }
        try await user.delete(on: req.db)
        return .noContent
    }
}
