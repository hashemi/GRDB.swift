import XCTest
#if GRDBCIPHER
    import GRDBCipher
#elseif GRDBCUSTOMSQLITE
    import GRDBCustomSQLite
#else
    import GRDB
#endif

private typealias Author = AssociationFixture.Author
private typealias Book = AssociationFixture.Book

class BelongsToJoinedRequestTests: GRDBTestCase {
    
    func testSimplestRequest() throws {
        let dbQueue = try makeDatabaseQueue()
        try AssociationFixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            let graph = try Book
                .joined(with: Book.author)
                .fetchAll(db)
            
            XCTAssertEqual(lastSQLQuery, "SELECT \"books\".* FROM \"books\" JOIN \"authors\" ON (\"authors\".\"id\" = \"books\".\"authorId\")")
            
            assertMatch(graph, [
                ["id": 1, "authorId": 2, "title": "Foe", "year": 1986],
                ["id": 2, "authorId": 2, "title": "Three Stories", "year": 2014],
                ["id": 3, "authorId": 3, "title": "Moby-Dick", "year": 1851],
                ["id": 4, "authorId": 4, "title": "New York 2140", "year": 2017],
                ["id": 5, "authorId": 4, "title": "2312", "year": 2012],
                ["id": 6, "authorId": 4, "title": "Blue Mars", "year": 1996],
                ["id": 7, "authorId": 4, "title": "Green Mars", "year": 1994],
                ["id": 8, "authorId": 4, "title": "Red Mars", "year": 1993],
                ])
        }
    }
    
    func testLeftRequestDerivation() throws {
        let dbQueue = try makeDatabaseQueue()
        try AssociationFixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            do {
                // filter before
                let graph = try Book
                    .filter(Column("year") < 2000)
                    .joined(with: Book.author)
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"books\".* FROM \"books\" JOIN \"authors\" ON (\"authors\".\"id\" = \"books\".\"authorId\") WHERE (\"books\".\"year\" < 2000)")
                
                assertMatch(graph, [
                    ["id": 1, "authorId": 2, "title": "Foe", "year": 1986],
                    ["id": 3, "authorId": 3, "title": "Moby-Dick", "year": 1851],
                    ["id": 6, "authorId": 4, "title": "Blue Mars", "year": 1996],
                    ["id": 7, "authorId": 4, "title": "Green Mars", "year": 1994],
                    ["id": 8, "authorId": 4, "title": "Red Mars", "year": 1993],
                    ])
            }
            
            do {
                // filter after
                let graph = try Book
                    .joined(with: Book.author)
                    .filter(Column("year") < 2000)
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"books\".* FROM \"books\" JOIN \"authors\" ON (\"authors\".\"id\" = \"books\".\"authorId\") WHERE (\"books\".\"year\" < 2000)")
                
                assertMatch(graph, [
                    ["id": 1, "authorId": 2, "title": "Foe", "year": 1986],
                    ["id": 3, "authorId": 3, "title": "Moby-Dick", "year": 1851],
                    ["id": 6, "authorId": 4, "title": "Blue Mars", "year": 1996],
                    ["id": 7, "authorId": 4, "title": "Green Mars", "year": 1994],
                    ["id": 8, "authorId": 4, "title": "Red Mars", "year": 1993],
                    ])
            }
            
            do {
                // order before
                let graph = try Book
                    .order(Column("title"))
                    .joined(with: Book.author)
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"books\".* FROM \"books\" JOIN \"authors\" ON (\"authors\".\"id\" = \"books\".\"authorId\") ORDER BY \"books\".\"title\"")
                
                assertMatch(graph, [
                    ["id": 5, "authorId": 4, "title": "2312", "year": 2012],
                    ["id": 6, "authorId": 4, "title": "Blue Mars", "year": 1996],
                    ["id": 1, "authorId": 2, "title": "Foe", "year": 1986],
                    ["id": 7, "authorId": 4, "title": "Green Mars", "year": 1994],
                    ["id": 3, "authorId": 3, "title": "Moby-Dick", "year": 1851],
                    ["id": 4, "authorId": 4, "title": "New York 2140", "year": 2017],
                    ["id": 8, "authorId": 4, "title": "Red Mars", "year": 1993],
                    ["id": 2, "authorId": 2, "title": "Three Stories", "year": 2014],
                    ])
            }
            
            do {
                // order after
                let graph = try Book
                    .joined(with: Book.author)
                    .order(Column("title"))
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"books\".* FROM \"books\" JOIN \"authors\" ON (\"authors\".\"id\" = \"books\".\"authorId\") ORDER BY \"books\".\"title\"")
                
                assertMatch(graph, [
                    ["id": 5, "authorId": 4, "title": "2312", "year": 2012],
                    ["id": 6, "authorId": 4, "title": "Blue Mars", "year": 1996],
                    ["id": 1, "authorId": 2, "title": "Foe", "year": 1986],
                    ["id": 7, "authorId": 4, "title": "Green Mars", "year": 1994],
                    ["id": 3, "authorId": 3, "title": "Moby-Dick", "year": 1851],
                    ["id": 4, "authorId": 4, "title": "New York 2140", "year": 2017],
                    ["id": 8, "authorId": 4, "title": "Red Mars", "year": 1993],
                    ["id": 2, "authorId": 2, "title": "Three Stories", "year": 2014],
                    ])
            }
        }
    }
    
    func testRightRequestDerivation() throws {
        let dbQueue = try makeDatabaseQueue()
        try AssociationFixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            do {
                // filtered authors
                let graph = try Book
                    .joined(with: Book.author.filter(Column("birthYear") >= 1900))
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"books\".* FROM \"books\" JOIN \"authors\" ON ((\"authors\".\"id\" = \"books\".\"authorId\") AND (\"authors\".\"birthYear\" >= 1900))")
                
                assertMatch(graph, [
                    ["id": 1, "authorId": 2, "title": "Foe", "year": 1986],
                    ["id": 2, "authorId": 2, "title": "Three Stories", "year": 2014],
                    ["id": 4, "authorId": 4, "title": "New York 2140", "year": 2017],
                    ["id": 5, "authorId": 4, "title": "2312", "year": 2012],
                    ["id": 6, "authorId": 4, "title": "Blue Mars", "year": 1996],
                    ["id": 7, "authorId": 4, "title": "Green Mars", "year": 1994],
                    ["id": 8, "authorId": 4, "title": "Red Mars", "year": 1993],
                    ])
            }
            
            do {
                // ordered books
                let graph = try Book
                    .joined(with: Book.author.order(Column("name")))
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"books\".* FROM \"books\" JOIN \"authors\" ON (\"authors\".\"id\" = \"books\".\"authorId\")")
                
                assertMatch(graph, [
                    ["id": 1, "authorId": 2, "title": "Foe", "year": 1986],
                    ["id": 2, "authorId": 2, "title": "Three Stories", "year": 2014],
                    ["id": 3, "authorId": 3, "title": "Moby-Dick", "year": 1851],
                    ["id": 4, "authorId": 4, "title": "New York 2140", "year": 2017],
                    ["id": 5, "authorId": 4, "title": "2312", "year": 2012],
                    ["id": 6, "authorId": 4, "title": "Blue Mars", "year": 1996],
                    ["id": 7, "authorId": 4, "title": "Green Mars", "year": 1994],
                    ["id": 8, "authorId": 4, "title": "Red Mars", "year": 1993],
                    ])
            }
        }
    }
    
    func testRecursion() throws {
        struct Person : TableMapping {
            static let databaseTableName = "persons"
        }
        
        let dbQueue = try makeDatabaseQueue()
        try dbQueue.inDatabase { db in
            try db.create(table: "persons") { t in
                t.column("id", .integer).primaryKey()
                t.column("parentId", .integer).references("persons")
            }
        }
        
        try dbQueue.inDatabase { db in
            do {
                let association = Person.belongsTo(Person.self)
                let request = Person.all().joined(with: association)
                try assertSQL(db, request, "SELECT \"persons1\".* FROM \"persons\" \"persons1\" JOIN \"persons\" \"persons2\" ON (\"persons2\".\"id\" = \"persons1\".\"parentId\")")
            }
        }
    }
    
    func testLeftAlias() throws {
        let dbQueue = try makeDatabaseQueue()
        try AssociationFixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            do {
                // alias first
                let request = Book.all()
                    .aliased("b")
                    .filter(Column("year") < 2000)
                    .joined(with: Book.author)
                try assertSQL(db, request, "SELECT \"b\".* FROM \"books\" \"b\" JOIN \"authors\" ON (\"authors\".\"id\" = \"b\".\"authorId\") WHERE (\"b\".\"year\" < 2000)")
            }
            
            do {
                // alias last
                let request = Book
                    .joined(with: Book.author)
                    .filter(Column("year") < 2000)
                    .aliased("b")
                try assertSQL(db, request, "SELECT \"b\".* FROM \"books\" \"b\" JOIN \"authors\" ON (\"authors\".\"id\" = \"b\".\"authorId\") WHERE (\"b\".\"year\" < 2000)")
            }
        }
    }
    
    func testRightAlias() throws {
        let dbQueue = try makeDatabaseQueue()
        try AssociationFixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            do {
                // alias first
                let request = Book.joined(with: Book.author.aliased("a").filter(Column("birthYear") >= 1900))
                try assertSQL(db, request, "SELECT \"books\".* FROM \"books\" JOIN \"authors\" \"a\" ON ((\"a\".\"id\" = \"books\".\"authorId\") AND (\"a\".\"birthYear\" >= 1900))")
            }
            
            do {
                // alias last
                let request = Book.joined(with: Book.author.filter(Column("birthYear") >= 1900).aliased("a"))
                try assertSQL(db, request, "SELECT \"books\".* FROM \"books\" JOIN \"authors\" \"a\" ON ((\"a\".\"id\" = \"books\".\"authorId\") AND (\"a\".\"birthYear\" >= 1900))")
            }
        }
    }
    
    func testLockedAlias() throws {
        let dbQueue = try makeDatabaseQueue()
        try AssociationFixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            do {
                // alias left
                let request = Book.joined(with: Book.author).aliased("AUTHORS")
                try assertSQL(db, request, "SELECT \"AUTHORS\".* FROM \"books\" \"AUTHORS\" JOIN \"authors\" \"authors1\" ON (\"authors1\".\"id\" = \"AUTHORS\".\"authorId\")")
            }
            
            do {
                // alias right
                let request = Book.joined(with: Book.author.aliased("BOOKS"))
                try assertSQL(db, request, "SELECT \"books1\".* FROM \"books\" \"books1\" JOIN \"authors\" \"BOOKS\" ON (\"BOOKS\".\"id\" = \"books1\".\"authorId\")")
            }
        }
    }
    
    func testConflictingAlias() throws {
        let dbQueue = try makeDatabaseQueue()
        try AssociationFixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            do {
                let request = Book.joined(with: Book.author.aliased("a")).aliased("A")
                _ = try request.fetchAll(db)
                XCTFail("Expected error")
            } catch let error as DatabaseError {
                XCTAssertEqual(error.resultCode, .SQLITE_ERROR)
                XCTAssertEqual(error.message!, "ambiguous alias: A")
                XCTAssertNil(error.sql)
                XCTAssertEqual(error.description, "SQLite error 1: ambiguous alias: A")
            }
        }
    }
}
