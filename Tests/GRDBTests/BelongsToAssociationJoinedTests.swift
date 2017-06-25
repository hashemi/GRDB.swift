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

class BelongsToAssociationJoinedTests: GRDBTestCase {
    
    func testSimplestRequest() throws {
        let dbQueue = try makeDatabaseQueue()
        try AssociationFixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            let graph = try Book
                .joined(with: Book.author)
                .fetchAll(db)
            
            XCTAssertEqual(lastSQLQuery, "SELECT \"books\".*, \"authors\".* FROM \"books\" JOIN \"authors\" ON (\"authors\".\"id\" = \"books\".\"authorId\")")
            
            assertMatch(graph, [
                (["id": 1, "authorId": 2, "title": "Foe", "year": 1986], ["id": 2, "name": "J. M. Coetzee", "birthYear": 1940]),
                (["id": 2, "authorId": 2, "title": "Three Stories", "year": 2014], ["id": 2, "name": "J. M. Coetzee", "birthYear": 1940]),
                (["id": 3, "authorId": 3, "title": "Moby-Dick", "year": 1851], ["id": 3, "name": "Herman Melville", "birthYear": 1819]),
                (["id": 4, "authorId": 4, "title": "New York 2140", "year": 2017], ["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952]),
                (["id": 5, "authorId": 4, "title": "2312", "year": 2012], ["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952]),
                (["id": 6, "authorId": 4, "title": "Blue Mars", "year": 1996], ["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952]),
                (["id": 7, "authorId": 4, "title": "Green Mars", "year": 1994], ["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952]),
                (["id": 8, "authorId": 4, "title": "Red Mars", "year": 1993], ["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952]),
                ])
        }
    }
    
    func testLeftRequestDerivation() throws {
        let dbQueue = try makeDatabaseQueue()
        try AssociationFixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            do {
                // filter before joined
                let graph = try Book
                    .filter(Column("year") < 2000)
                    .joined(with: Book.author)
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"books\".*, \"authors\".* FROM \"books\" JOIN \"authors\" ON (\"authors\".\"id\" = \"books\".\"authorId\") WHERE (\"books\".\"year\" < 2000)")
                
                assertMatch(graph, [
                    (["id": 1, "authorId": 2, "title": "Foe", "year": 1986], ["id": 2, "name": "J. M. Coetzee", "birthYear": 1940]),
                    (["id": 3, "authorId": 3, "title": "Moby-Dick", "year": 1851], ["id": 3, "name": "Herman Melville", "birthYear": 1819]),
                    (["id": 6, "authorId": 4, "title": "Blue Mars", "year": 1996], ["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952]),
                    (["id": 7, "authorId": 4, "title": "Green Mars", "year": 1994], ["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952]),
                    (["id": 8, "authorId": 4, "title": "Red Mars", "year": 1993], ["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952]),
                    ])
            }
            
            do {
                // filter after joined
                let graph = try Book
                    .joined(with: Book.author)
                    .filter(Column("year") < 2000)
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"books\".*, \"authors\".* FROM \"books\" JOIN \"authors\" ON (\"authors\".\"id\" = \"books\".\"authorId\") WHERE (\"books\".\"year\" < 2000)")
                
                assertMatch(graph, [
                    (["id": 1, "authorId": 2, "title": "Foe", "year": 1986], ["id": 2, "name": "J. M. Coetzee", "birthYear": 1940]),
                    (["id": 3, "authorId": 3, "title": "Moby-Dick", "year": 1851], ["id": 3, "name": "Herman Melville", "birthYear": 1819]),
                    (["id": 6, "authorId": 4, "title": "Blue Mars", "year": 1996], ["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952]),
                    (["id": 7, "authorId": 4, "title": "Green Mars", "year": 1994], ["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952]),
                    (["id": 8, "authorId": 4, "title": "Red Mars", "year": 1993], ["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952]),
                    ])
            }
            
            do {
                // order before joined
                let graph = try Book
                    .order(Column("title"))
                    .joined(with: Book.author)
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"books\".*, \"authors\".* FROM \"books\" JOIN \"authors\" ON (\"authors\".\"id\" = \"books\".\"authorId\") ORDER BY \"books\".\"title\"")
                
                assertMatch(graph, [
                    (["id": 5, "authorId": 4, "title": "2312", "year": 2012], ["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952]),
                    (["id": 6, "authorId": 4, "title": "Blue Mars", "year": 1996], ["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952]),
                    (["id": 1, "authorId": 2, "title": "Foe", "year": 1986], ["id": 2, "name": "J. M. Coetzee", "birthYear": 1940]),
                    (["id": 7, "authorId": 4, "title": "Green Mars", "year": 1994], ["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952]),
                    (["id": 3, "authorId": 3, "title": "Moby-Dick", "year": 1851], ["id": 3, "name": "Herman Melville", "birthYear": 1819]),
                    (["id": 4, "authorId": 4, "title": "New York 2140", "year": 2017], ["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952]),
                    (["id": 8, "authorId": 4, "title": "Red Mars", "year": 1993], ["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952]),
                    (["id": 2, "authorId": 2, "title": "Three Stories", "year": 2014], ["id": 2, "name": "J. M. Coetzee", "birthYear": 1940]),
                    ])
            }
            
            do {
                // order after joined
                let graph = try Book
                    .joined(with: Book.author)
                    .order(Column("title"))
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"books\".*, \"authors\".* FROM \"books\" JOIN \"authors\" ON (\"authors\".\"id\" = \"books\".\"authorId\") ORDER BY \"books\".\"title\"")
                
                assertMatch(graph, [
                    (["id": 5, "authorId": 4, "title": "2312", "year": 2012], ["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952]),
                    (["id": 6, "authorId": 4, "title": "Blue Mars", "year": 1996], ["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952]),
                    (["id": 1, "authorId": 2, "title": "Foe", "year": 1986], ["id": 2, "name": "J. M. Coetzee", "birthYear": 1940]),
                    (["id": 7, "authorId": 4, "title": "Green Mars", "year": 1994], ["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952]),
                    (["id": 3, "authorId": 3, "title": "Moby-Dick", "year": 1851], ["id": 3, "name": "Herman Melville", "birthYear": 1819]),
                    (["id": 4, "authorId": 4, "title": "New York 2140", "year": 2017], ["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952]),
                    (["id": 8, "authorId": 4, "title": "Red Mars", "year": 1993], ["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952]),
                    (["id": 2, "authorId": 2, "title": "Three Stories", "year": 2014], ["id": 2, "name": "J. M. Coetzee", "birthYear": 1940]),
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
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"books\".*, \"authors\".* FROM \"books\" JOIN \"authors\" ON ((\"authors\".\"id\" = \"books\".\"authorId\") AND (\"authors\".\"birthYear\" >= 1900))")
                
                assertMatch(graph, [
                    (["id": 1, "authorId": 2, "title": "Foe", "year": 1986], ["id": 2, "name": "J. M. Coetzee", "birthYear": 1940]),
                    (["id": 2, "authorId": 2, "title": "Three Stories", "year": 2014], ["id": 2, "name": "J. M. Coetzee", "birthYear": 1940]),
                    (["id": 4, "authorId": 4, "title": "New York 2140", "year": 2017], ["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952]),
                    (["id": 5, "authorId": 4, "title": "2312", "year": 2012], ["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952]),
                    (["id": 6, "authorId": 4, "title": "Blue Mars", "year": 1996], ["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952]),
                    (["id": 7, "authorId": 4, "title": "Green Mars", "year": 1994], ["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952]),
                    (["id": 8, "authorId": 4, "title": "Red Mars", "year": 1993], ["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952]),
                    ])
            }
            
            do {
                // ordered books
                let graph = try Book
                    .joined(with: Book.author.order(Column("name")))
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"books\".*, \"authors\".* FROM \"books\" JOIN \"authors\" ON (\"authors\".\"id\" = \"books\".\"authorId\") ORDER BY \"authors\".\"name\"")
                
                assertMatch(graph, [
                    (["id": 3, "authorId": 3, "title": "Moby-Dick", "year": 1851], ["id": 3, "name": "Herman Melville", "birthYear": 1819]),
                    (["id": 1, "authorId": 2, "title": "Foe", "year": 1986], ["id": 2, "name": "J. M. Coetzee", "birthYear": 1940]),
                    (["id": 2, "authorId": 2, "title": "Three Stories", "year": 2014], ["id": 2, "name": "J. M. Coetzee", "birthYear": 1940]),
                    (["id": 4, "authorId": 4, "title": "New York 2140", "year": 2017], ["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952]),
                    (["id": 5, "authorId": 4, "title": "2312", "year": 2012], ["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952]),
                    (["id": 6, "authorId": 4, "title": "Blue Mars", "year": 1996], ["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952]),
                    (["id": 7, "authorId": 4, "title": "Green Mars", "year": 1994], ["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952]),
                    (["id": 8, "authorId": 4, "title": "Red Mars", "year": 1993], ["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952]),
                    ])
            }
        }
    }
}
