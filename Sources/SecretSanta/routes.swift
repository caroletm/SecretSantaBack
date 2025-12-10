import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        "It works!"
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }
    
//    app.get("test-email") { req async throws -> String in
//    try await BrevoEmailService.sendEmail(
//        req: req,
//        to: "trem.carole@gmail.com",
//        subject: "Test Secret Santa",
//        html: "<h1>Hello 🎅</h1><p>Test Vapor essai 2333 → Brevo</p>"
//    )
//    return "Email envoyé !"
//}
    
    try app.register(collection: UserController())
    try app.register(collection: EventController())
    try app.register(collection: ParticipantController())
    try app.register(collection: LetterController())
}
