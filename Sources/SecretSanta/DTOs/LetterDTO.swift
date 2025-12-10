//
//  LetterDTO.swift
//  SecretSanta
//
//  Created by caroletm on 10/12/2025.
//

import Fluent
import Vapor

struct LetterCreateDTO: Content {
    var message: String
    var signature: String
    var typeLetter: TypeLetter
    var expediteurId: UUID
    var destinataireId: UUID
}

struct LetterDTO: Content {
    var id: UUID?
    var message: String
    var signature: String
    var typeLetter: TypeLetter
    var date: Date?
    var expediteur: UUID
    var destinataire: UUID
}
