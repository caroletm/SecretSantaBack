import NIOSSL
import Fluent
import FluentMySQLDriver
import Vapor
import Gatekeeper
import JWT
import FluentSQLiteDriver
import FluentSQL



// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    guard let databaseHost = Environment.get("DATABASE_HOST"),
          let databaseUsername = Environment.get("DATABASE_USERNAME"),
          let databasePassword = Environment.get("DATABASE_PASSWORD"),
          let databaseName = Environment.get("DATABASE_NAME") else {
        fatalError("Variables manquantes : DATABASE_HOST, DATABASE_USERNAME, DATABASE_PASSWORD et DATABASE_NAME sont obligatoires")
    }

    // MySQL tourne dans Docker sur la même machine avec un certificat auto-signé : on chiffre sans vérifier le certificat (comme CleanQuest)
    var tlsConfiguration = TLSConfiguration.makeClientConfiguration()
    tlsConfiguration.certificateVerification = .none

    app.databases.use(
        .mysql(
            hostname: databaseHost,
            port: Environment.get("DATABASE_PORT").flatMap(Int.init) ?? 3306,
            username: databaseUsername,
            password: databasePassword,
            database: databaseName,
            tlsConfiguration: tlsConfiguration
        ),
        as: .mysql
    )

    let brevoAPIKey = Environment.get("BREVO_API_KEY") ?? ""
    if brevoAPIKey.isEmpty {
        app.logger.warning("BREVO_API_KEY manquante : les emails d'invitation ne partiront pas")
    }
    app.storage[BrevoAPIKey.self] = brevoAPIKey

    // register routes
    
    app.migrations.add(CreateUser())
    app.migrations.add(CreateEvent())
    app.migrations.add(UpdateEvent())
    app.migrations.add(CreateParticipant())
    app.migrations.add(UpdateParticipant())
    app.migrations.add(CreateLetter())
    app.migrations.add(UpdateLetter())
    app.migrations.add(CreateTirage())
    app.migrations.add(UpdateTirage())
    app.migrations.add(UpdateTirageEvent())
    app.migrations.add(UpdateEventDescriptionToText())
    app.migrations.add(UpdateLetterMessageToText())
    app.migrations.add(UpdateLetterCascade())
//    try await app.autoMigrate()
    

    
    //Test rapide de connexion
//    if let sql = app.db(.mysql) as? (any SQLDatabase) {
//        sql.raw("SELECT 1").run().whenComplete { response in
//            print(response)
//        }
//    } else {
//        print("⚠️ Le driver SQL n'est pas disponible (cast vers SQLDatabase impossible)")
//    }
    
    // Un secret court permet de fabriquer de faux tokens : on refuse de démarrer plutôt que de tourner avec
    guard let jwtSecret = Environment.get("JWT_SECRET"), jwtSecret.count >= 32 else {
        fatalError("JWT_SECRET manquant ou trop court (32 caractères minimum)")
    }
    
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .custom("https://mysecretsanta.cloud"),
        allowedMethods: [.GET, .POST, .PUT, .DELETE, .OPTIONS],
        allowedHeaders: [.accept, .authorization, .contentType, .origin],
        cacheExpiration: 800
    )

    app.middleware.use(CORSMiddleware(configuration: corsConfiguration))
    
    try routes(app)
}
