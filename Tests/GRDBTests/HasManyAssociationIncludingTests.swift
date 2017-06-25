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

class HasManyAssociationIncludingTests: GRDBTestCase {
    
    // TODO: tests for left implicit row id, and compound keys
    
    func testSimplestRequest() throws {
        let dbQueue = try makeDatabaseQueue()
        try AssociationFixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            let graph = try Author
                .including(Author.books)
                .fetchAll(db)
            
            XCTAssertEqual(sqlQueries[sqlQueries.count - 2], "SELECT * FROM \"authors\"")
            XCTAssertEqual(sqlQueries[sqlQueries.count - 1], "SELECT * FROM \"books\" WHERE (\"authorId\" IN (1, 2, 3, 4))")
            
            assertMatch(graph, [
                (["id": 1, "name": "Gwendal Roué", "birthYear": 1973], []),
                (["id": 2, "name": "J. M. Coetzee", "birthYear": 1940], [
                    ["id": 1, "authorId": 2, "title": "Foe", "year": 1986],
                    ["id": 2, "authorId": 2, "title": "Three Stories", "year": 2014],
                    ]),
                (["id": 3, "name": "Herman Melville", "birthYear": 1819], [
                    ["id": 3, "authorId": 3, "title": "Moby-Dick", "year": 1851],
                    ]),
                (["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952], [
                    ["id": 4, "authorId": 4, "title": "New York 2140", "year": 2017],
                    ["id": 5, "authorId": 4, "title": "2312", "year": 2012],
                    ["id": 6, "authorId": 4, "title": "Blue Mars", "year": 1996],
                    ["id": 7, "authorId": 4, "title": "Green Mars", "year": 1994],
                    ["id": 8, "authorId": 4, "title": "Red Mars", "year": 1993],
                    ]),
                ])
        }
    }

    func testLeftRequestDerivation() throws {
        let dbQueue = try makeDatabaseQueue()
        try AssociationFixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            do {
                // filter before including
                let graph = try Author
                    .filter(Column("birthYear") >= 1900)
                    .including(Author.books)
                    .fetchAll(db)
                
                XCTAssertEqual(sqlQueries[sqlQueries.count - 2], "SELECT * FROM \"authors\" WHERE (\"birthYear\" >= 1900)")
                XCTAssertEqual(sqlQueries[sqlQueries.count - 1], "SELECT * FROM \"books\" WHERE (\"authorId\" IN (1, 2, 4))")
                
                assertMatch(graph, [
                    (["id": 1, "name": "Gwendal Roué", "birthYear": 1973], []),
                    (["id": 2, "name": "J. M. Coetzee", "birthYear": 1940], [
                        ["id": 1, "authorId": 2, "title": "Foe", "year": 1986],
                        ["id": 2, "authorId": 2, "title": "Three Stories", "year": 2014],
                        ]),
                    (["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952], [
                        ["id": 4, "authorId": 4, "title": "New York 2140", "year": 2017],
                        ["id": 5, "authorId": 4, "title": "2312", "year": 2012],
                        ["id": 6, "authorId": 4, "title": "Blue Mars", "year": 1996],
                        ["id": 7, "authorId": 4, "title": "Green Mars", "year": 1994],
                        ["id": 8, "authorId": 4, "title": "Red Mars", "year": 1993],
                        ]),
                    ])
            }
            
            do {
                // filter after including
                let graph = try Author
                    .including(Author.books)
                    .filter(Column("birthYear") >= 1900)
                    .fetchAll(db)
                
                XCTAssertEqual(sqlQueries[sqlQueries.count - 2], "SELECT * FROM \"authors\" WHERE (\"birthYear\" >= 1900)")
                XCTAssertEqual(sqlQueries[sqlQueries.count - 1], "SELECT * FROM \"books\" WHERE (\"authorId\" IN (1, 2, 4))")
                
                assertMatch(graph, [
                    (["id": 1, "name": "Gwendal Roué", "birthYear": 1973], []),
                    (["id": 2, "name": "J. M. Coetzee", "birthYear": 1940], [
                        ["id": 1, "authorId": 2, "title": "Foe", "year": 1986],
                        ["id": 2, "authorId": 2, "title": "Three Stories", "year": 2014],
                        ]),
                    (["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952], [
                        ["id": 4, "authorId": 4, "title": "New York 2140", "year": 2017],
                        ["id": 5, "authorId": 4, "title": "2312", "year": 2012],
                        ["id": 6, "authorId": 4, "title": "Blue Mars", "year": 1996],
                        ["id": 7, "authorId": 4, "title": "Green Mars", "year": 1994],
                        ["id": 8, "authorId": 4, "title": "Red Mars", "year": 1993],
                        ]),
                    ])
            }
            
            do {
                // order before including
                let graph = try Author
                    .order(Column("name").desc)
                    .including(Author.books)
                    .fetchAll(db)
                
                XCTAssertEqual(sqlQueries[sqlQueries.count - 2], "SELECT * FROM \"authors\" ORDER BY \"name\" DESC")
                XCTAssertEqual(sqlQueries[sqlQueries.count - 1], "SELECT * FROM \"books\" WHERE (\"authorId\" IN (4, 2, 3, 1))")
                
                assertMatch(graph, [
                    (["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952], [
                        ["id": 4, "authorId": 4, "title": "New York 2140", "year": 2017],
                        ["id": 5, "authorId": 4, "title": "2312", "year": 2012],
                        ["id": 6, "authorId": 4, "title": "Blue Mars", "year": 1996],
                        ["id": 7, "authorId": 4, "title": "Green Mars", "year": 1994],
                        ["id": 8, "authorId": 4, "title": "Red Mars", "year": 1993],
                        ]),
                    (["id": 2, "name": "J. M. Coetzee", "birthYear": 1940], [
                        ["id": 1, "authorId": 2, "title": "Foe", "year": 1986],
                        ["id": 2, "authorId": 2, "title": "Three Stories", "year": 2014],
                        ]),
                    (["id": 3, "name": "Herman Melville", "birthYear": 1819], [
                        ["id": 3, "authorId": 3, "title": "Moby-Dick", "year": 1851],
                        ]),
                    (["id": 1, "name": "Gwendal Roué", "birthYear": 1973], []),
                    ])
            }
            
            do {
                // order after including
                let graph = try Author
                    .including(Author.books)
                    .order(Column("name").desc)
                    .fetchAll(db)
                
                XCTAssertEqual(sqlQueries[sqlQueries.count - 2], "SELECT * FROM \"authors\" ORDER BY \"name\" DESC")
                XCTAssertEqual(sqlQueries[sqlQueries.count - 1], "SELECT * FROM \"books\" WHERE (\"authorId\" IN (4, 2, 3, 1))")
                
                assertMatch(graph, [
                    (["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952], [
                        ["id": 4, "authorId": 4, "title": "New York 2140", "year": 2017],
                        ["id": 5, "authorId": 4, "title": "2312", "year": 2012],
                        ["id": 6, "authorId": 4, "title": "Blue Mars", "year": 1996],
                        ["id": 7, "authorId": 4, "title": "Green Mars", "year": 1994],
                        ["id": 8, "authorId": 4, "title": "Red Mars", "year": 1993],
                        ]),
                    (["id": 2, "name": "J. M. Coetzee", "birthYear": 1940], [
                        ["id": 1, "authorId": 2, "title": "Foe", "year": 1986],
                        ["id": 2, "authorId": 2, "title": "Three Stories", "year": 2014],
                        ]),
                    (["id": 3, "name": "Herman Melville", "birthYear": 1819], [
                        ["id": 3, "authorId": 3, "title": "Moby-Dick", "year": 1851],
                        ]),
                    (["id": 1, "name": "Gwendal Roué", "birthYear": 1973], []),
                    ])
            }
        }
    }
    
    func testRightRequestDerivation() throws {
        let dbQueue = try makeDatabaseQueue()
        try AssociationFixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            do {
                // filtered books
                let graph = try Author
                    .including(Author.books.filter(Column("year") < 2000))
                    .fetchAll(db)
                
                XCTAssertEqual(sqlQueries[sqlQueries.count - 2], "SELECT * FROM \"authors\"")
                XCTAssertEqual(sqlQueries[sqlQueries.count - 1], "SELECT * FROM \"books\" WHERE ((\"year\" < 2000) AND (\"authorId\" IN (1, 2, 3, 4)))")
                
                assertMatch(graph, [
                    (["id": 1, "name": "Gwendal Roué", "birthYear": 1973], []),
                    (["id": 2, "name": "J. M. Coetzee", "birthYear": 1940], [
                        ["id": 1, "authorId": 2, "title": "Foe", "year": 1986],
                        ]),
                    (["id": 3, "name": "Herman Melville", "birthYear": 1819], [
                        ["id": 3, "authorId": 3, "title": "Moby-Dick", "year": 1851],
                        ]),
                    (["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952], [
                        ["id": 6, "authorId": 4, "title": "Blue Mars", "year": 1996],
                        ["id": 7, "authorId": 4, "title": "Green Mars", "year": 1994],
                        ["id": 8, "authorId": 4, "title": "Red Mars", "year": 1993],
                        ]),
                    ])
            }
            
            do {
                // ordered books
                let graph = try Author
                    .including(Author.books.order(Column("title")))
                    .fetchAll(db)
                
                XCTAssertEqual(sqlQueries[sqlQueries.count - 2], "SELECT * FROM \"authors\"")
                XCTAssertEqual(sqlQueries[sqlQueries.count - 1], "SELECT * FROM \"books\" WHERE (\"authorId\" IN (1, 2, 3, 4)) ORDER BY \"title\"")
                
                assertMatch(graph, [
                    (["id": 1, "name": "Gwendal Roué", "birthYear": 1973], []),
                    (["id": 2, "name": "J. M. Coetzee", "birthYear": 1940], [
                        ["id": 1, "authorId": 2, "title": "Foe", "year": 1986],
                        ["id": 2, "authorId": 2, "title": "Three Stories", "year": 2014],
                        ]),
                    (["id": 3, "name": "Herman Melville", "birthYear": 1819], [
                        ["id": 3, "authorId": 3, "title": "Moby-Dick", "year": 1851],
                        ]),
                    (["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952], [
                        ["id": 5, "authorId": 4, "title": "2312", "year": 2012],
                        ["id": 6, "authorId": 4, "title": "Blue Mars", "year": 1996],
                        ["id": 7, "authorId": 4, "title": "Green Mars", "year": 1994],
                        ["id": 4, "authorId": 4, "title": "New York 2140", "year": 2017],
                        ["id": 8, "authorId": 4, "title": "Red Mars", "year": 1993],
                        ]),
                    ])
            }
        }
    }
}
