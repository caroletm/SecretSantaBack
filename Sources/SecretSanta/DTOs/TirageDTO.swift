//
//  TirageDTO.swift
//  SecretSanta
//
//  Created by caroletm on 10/12/2025.
//

import Fluent
import Vapor

struct TirageDTO: Content {
    var giverId: UUID
    var receiverId: UUID
}
