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

    app.databases.use(DatabaseConfigurationFactory.mysql(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? 3306,
        username: Environment.get("DATABASE_USERNAME") ?? "root",
        password: Environment.get("DATABASE_PASSWORD") ?? "",
        database: Environment.get("DATABASE_NAME") ?? "SecretSanta"
    ), as: .mysql)

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
    try await app.autoMigrate()
    
    //Test rapide de connexion
    if let sql = app.db(.mysql) as? (any SQLDatabase) {
        sql.raw("SELECT 1").run().whenComplete { response in
            print(response)
        }
    } else {
        print("⚠️ Le driver SQL n'est pas disponible (cast vers SQLDatabase impossible)")
    }
    
    try routes(app)
}
