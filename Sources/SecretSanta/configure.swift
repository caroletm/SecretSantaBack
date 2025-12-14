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

    app.databases.use(
        .mysql(
            hostname: Environment.get("DATABASE_HOST")!,
            port: Environment.get("DATABASE_PORT").flatMap(Int.init) ?? 3306,
            username: Environment.get("DATABASE_USERNAME")!,
            password: Environment.get("DATABASE_PASSWORD")!,
            database: Environment.get("DATABASE_NAME")!,
            tlsConfiguration: .makeClientConfiguration()
        ),
        as: .mysql
    )
    
    let brevoAPIKey = Environment.get("BREVO_API_KEY") ?? ""
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
//    try await app.autoMigrate()
    

    
    //Test rapide de connexion
//    if let sql = app.db(.mysql) as? (any SQLDatabase) {
//        sql.raw("SELECT 1").run().whenComplete { response in
//            print(response)
//        }
//    } else {
//        print("⚠️ Le driver SQL n'est pas disponible (cast vers SQLDatabase impossible)")
//    }
    
    enum JWTConfig {
        static func signer() -> JWTSigner {
            guard let secret = Environment.get("JWT_SECRET") else {
                fatalError("JWT_SECRET is not set")
            }
            return JWTSigner.hs256(key: secret)
        }
    }
    
    try routes(app)
}
