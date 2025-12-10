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
        //        let users = routes.grouped("users")
        
    }
    
    //GET/users
    // Récupère tous les utilisateurs enregistrés.
    // Accessible sans authentification.
    // Retour : [UserDTO]
    @Sendable
    func getAllUsers(_ req: Request) async throws -> [UserDTO] {
        let users = try await User.query(on: req.db).all()
        return users.map { user in
            UserDTO(
                id: user.id,
                name : user.name,
                email: user.email,
                telephone: user.telephone
            )
        }
    }
    
    //GET/:id
    //Recupere un user par son ID
    @Sendable
    func getUserById(_ req: Request) async throws -> User {
        guard let user = try await User.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        return user
    }
    
    // POST /users
    // Création d’un nouveau compte utilisateur.
    // Vérifie :
    //   - Email non déjà utilisé
    //   - Mot de passe ≥ 8 caractères
    @Sendable
    func createUser(_ req: Request) async throws -> UserDTO {
        let dto = try req.content.decode(UserCreateDTO.self)
        
        if try await User.query(on: req.db)
            .filter(\.$email == dto.email)
            .first() != nil {
            throw Abort(.badRequest, reason: "Un utilisateur avec cet email existe déjà")
        }
        
        if dto.password.count < 6 {
            throw Abort(.badRequest, reason: "Le mot de passe doit contenir au moins 6 caractères.")
        }
        let passwordHashed = try Bcrypt.hash(dto.password)
        
        let user = User(
            name: dto.name,
            email: dto.email,
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
        
        guard let user = try await User.query(on: req.db)
            .filter(\.$email == userData.email)
            .first() else {
            throw Abort(.unauthorized, reason: "Email incorrect")
        }
        
        guard try Bcrypt.verify(userData.password, created: user.password) else {
            throw Abort(.unauthorized, reason: "Mot de passe incorrect")
        }
        
        let payload = UserPayload(id: user.id!)
        let signer = JWTSigner.hs256(key: "LOUVRE123")
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
    
    // DELETE /users/:id
    // Supprime un utilisateur via son ID.
    // Actuellement non protégé → à sécuriser plus tard.
    //
    // Retour : 204 No Content
    @Sendable
    func deleteUserById(_ req: Request) async throws -> Response {
        guard let user = try await User.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.badRequest, reason: "Id invalide")
        }
        try await user.delete(on: req.db)
        return Response(status: .noContent)
    }
}
