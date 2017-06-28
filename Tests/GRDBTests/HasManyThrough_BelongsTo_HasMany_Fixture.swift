import XCTest
#if GRDBCIPHER
    import GRDBCipher
#elseif GRDBCUSTOMSQLITE
    import GRDBCustomSQLite
#else
    import GRDB
#endif

struct HasManyThrough_BelongsTo_HasMany_Fixture {
    
    struct Reader : TableMapping, RowConvertible, Persistable {
        static let databaseTableName = "readers"
        let email: String
        let libraryId: Int64?
        
        init(row: Row) {
            email = row.value(named: "email")
            libraryId = row.value(named: "libraryId")
        }
        
        func encode(to container: inout PersistenceContainer) {
            container["email"] = email
            container["libraryId"] = libraryId
        }
        
        static let library = belongsTo(Library.self)
        static let books = hasMany(Library.books, through: library)
    }
    
    struct Library : TableMapping, RowConvertible, Persistable {
        static let databaseTableName = "libraries"
        let id: Int64
        let name: String
        
        init(row: Row) {
            id = row.value(named: "id")
            name = row.value(named: "name")
        }
        
        func encode(to container: inout PersistenceContainer) {
            container["id"] = id
            container["name"] = name
        }
        
        static let books = hasMany(Book.self)
    }
    
    struct Book : TableMapping, RowConvertible, Persistable {
        static let databaseTableName = "books"
        let isbn: String
        let title: String
        let libraryId: Int64?
        
        init(row: Row) {
            isbn = row.value(named: "isbn")
            title = row.value(named: "title")
            libraryId = row.value(named: "libraryId")
        }
        
        func encode(to container: inout PersistenceContainer) {
            container["isbn"] = isbn
            container["title"] = title
            container["libraryId"] = libraryId
        }
    }
    
    var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        
        migrator.registerMigration("fixtures") { db in
            try db.create(table: "libraries") { t in
                t.column("id", .integer).primaryKey()
                t.column("name", .text)
            }
            
            let library1 = Library(row: ["id": 1, "name": "Public Library"])
            try library1.insert(db)
            let library2 = Library(row: ["id": 2, "name": "Secret Library"])
            try library2.insert(db)
            let library3 = Library(row: ["id": 3, "name": "Empty Library"])
            try library3.insert(db)
            
            try db.create(table: "readers") { t in
                t.column("email", .text).primaryKey()
                t.column("libraryId", .integer).references("libraries")
            }
            
            try Reader(row: ["email": "arthur@example.com", "libraryId": nil]).insert(db)
            try Reader(row: ["email": "barbara@example.com", "libraryId": library1.id]).insert(db)
            try Reader(row: ["email": "craig@example.com", "libraryId": library2.id]).insert(db)
            try Reader(row: ["email": "david@example.com", "libraryId": library2.id]).insert(db)
            try Reader(row: ["email": "eve@example.com", "libraryId": library3.id]).insert(db)
            
            try db.create(table: "books") { t in
                t.column("isbn", .text).primaryKey()
                t.column("title", .text)
                t.column("libraryId", .integer).references("libraries")
            }
            
            try Book(row: ["isbn": "book1", "title": "Moby-Dick", "libraryId": nil]).insert(db)
            try Book(row: ["isbn": "book2", "title": "The Fellowship of the Ring", "libraryId": library1.id]).insert(db)
            try Book(row: ["isbn": "book3", "title": "Walden", "libraryId": library1.id]).insert(db)
            try Book(row: ["isbn": "book4", "title": "Le Comte de Monte-Cristo", "libraryId": library1.id]).insert(db)
            try Book(row: ["isbn": "book5", "title": "Querelle de Brest", "libraryId": library2.id]).insert(db)
            try Book(row: ["isbn": "book6", "title": "Eden, Eden, Eden", "libraryId": library2.id]).insert(db)
        }
        
        return migrator
    }
}
