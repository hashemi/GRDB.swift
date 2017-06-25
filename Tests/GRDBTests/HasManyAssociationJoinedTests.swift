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

class HasManyAssociationJoinedTests: GRDBTestCase {
    
    // TODO: tests for left implicit row id, and compound keys
    // TODO: test fetchOne, fetchCursor
    // TODO: test sql snippets with table aliases
    // TODO: test left and right derivations at the same time
    
    func testSimplestRequest() throws {
        let dbQueue = try makeDatabaseQueue()
        try AssociationFixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            let graph = try Author
                .joined(with: Author.books)
                .fetchAll(db)
            
            XCTAssertEqual(lastSQLQuery, "SELECT \"left\".*, \"right\".* FROM \"authors\" AS \"left\" JOIN \"books\" AS \"right\" ON (\"right\".\"authorId\" = \"left\".\"id\")")
            
            assertMatch(graph, [
                (["id": 2, "name": "J. M. Coetzee", "birthYear": 1940], ["id": 1, "authorId": 2, "title": "Foe", "year": 1986]),
                (["id": 2, "name": "J. M. Coetzee", "birthYear": 1940], ["id": 2, "authorId": 2, "title": "Three Stories", "year": 2014]),
                (["id": 3, "name": "Herman Melville", "birthYear": 1819], ["id": 3, "authorId": 3, "title": "Moby-Dick", "year": 1851]),
                (["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952], ["id": 4, "authorId": 4, "title": "New York 2140", "year": 2017]),
                (["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952], ["id": 5, "authorId": 4, "title": "2312", "year": 2012]),
                (["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952], ["id": 6, "authorId": 4, "title": "Blue Mars", "year": 1996]),
                (["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952], ["id": 7, "authorId": 4, "title": "Green Mars", "year": 1994]),
                (["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952], ["id": 8, "authorId": 4, "title": "Red Mars", "year": 1993]),
                ])
        }
    }
    
    func testLeftRequestDerivation() throws {
        let dbQueue = try makeDatabaseQueue()
        try AssociationFixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            do {
                // filter before joined
                let graph = try Author
                    .filter(Column("birthYear") >= 1900)
                    .joined(with: Author.books)
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"left\".*, \"right\".* FROM \"authors\" AS \"left\" JOIN \"books\" AS \"right\" ON (\"right\".\"authorId\" = \"left\".\"id\") WHERE (\"left\".\"birthYear\" >= 1900)")
                
                assertMatch(graph, [
                    (["id": 2, "name": "J. M. Coetzee", "birthYear": 1940], ["id": 1, "authorId": 2, "title": "Foe", "year": 1986]),
                    (["id": 2, "name": "J. M. Coetzee", "birthYear": 1940], ["id": 2, "authorId": 2, "title": "Three Stories", "year": 2014]),
                    (["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952], ["id": 4, "authorId": 4, "title": "New York 2140", "year": 2017]),
                    (["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952], ["id": 5, "authorId": 4, "title": "2312", "year": 2012]),
                    (["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952], ["id": 6, "authorId": 4, "title": "Blue Mars", "year": 1996]),
                    (["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952], ["id": 7, "authorId": 4, "title": "Green Mars", "year": 1994]),
                    (["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952], ["id": 8, "authorId": 4, "title": "Red Mars", "year": 1993]),
                    ])
            }
            
            do {
                // filter after joined
                let graph = try Author
                    .joined(with: Author.books)
                    .filter(Column("birthYear") >= 1900)
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"left\".*, \"right\".* FROM \"authors\" AS \"left\" JOIN \"books\" AS \"right\" ON (\"right\".\"authorId\" = \"left\".\"id\") WHERE (\"left\".\"birthYear\" >= 1900)")
                
                assertMatch(graph, [
                    (["id": 2, "name": "J. M. Coetzee", "birthYear": 1940], ["id": 1, "authorId": 2, "title": "Foe", "year": 1986]),
                    (["id": 2, "name": "J. M. Coetzee", "birthYear": 1940], ["id": 2, "authorId": 2, "title": "Three Stories", "year": 2014]),
                    (["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952], ["id": 4, "authorId": 4, "title": "New York 2140", "year": 2017]),
                    (["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952], ["id": 5, "authorId": 4, "title": "2312", "year": 2012]),
                    (["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952], ["id": 6, "authorId": 4, "title": "Blue Mars", "year": 1996]),
                    (["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952], ["id": 7, "authorId": 4, "title": "Green Mars", "year": 1994]),
                    (["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952], ["id": 8, "authorId": 4, "title": "Red Mars", "year": 1993]),
                    ])
            }
            
            do {
                // order before joined
                let graph = try Author
                    .order(Column("name").desc)
                    .joined(with: Author.books)
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"left\".*, \"right\".* FROM \"authors\" AS \"left\" JOIN \"books\" AS \"right\" ON (\"right\".\"authorId\" = \"left\".\"id\") ORDER BY \"left\".\"name\" DESC")
                
                assertMatch(graph, [
                    (["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952], ["id": 4, "authorId": 4, "title": "New York 2140", "year": 2017]),
                    (["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952], ["id": 5, "authorId": 4, "title": "2312", "year": 2012]),
                    (["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952], ["id": 6, "authorId": 4, "title": "Blue Mars", "year": 1996]),
                    (["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952], ["id": 7, "authorId": 4, "title": "Green Mars", "year": 1994]),
                    (["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952], ["id": 8, "authorId": 4, "title": "Red Mars", "year": 1993]),
                    (["id": 2, "name": "J. M. Coetzee", "birthYear": 1940], ["id": 1, "authorId": 2, "title": "Foe", "year": 1986]),
                    (["id": 2, "name": "J. M. Coetzee", "birthYear": 1940], ["id": 2, "authorId": 2, "title": "Three Stories", "year": 2014]),
                    (["id": 3, "name": "Herman Melville", "birthYear": 1819], ["id": 3, "authorId": 3, "title": "Moby-Dick", "year": 1851]),
                    ])
            }
            
            do {
                // order after joined
                let graph = try Author
                    .joined(with: Author.books)
                    .order(Column("name").desc)
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"left\".*, \"right\".* FROM \"authors\" AS \"left\" JOIN \"books\" AS \"right\" ON (\"right\".\"authorId\" = \"left\".\"id\") ORDER BY \"left\".\"name\" DESC")
                
                assertMatch(graph, [
                    (["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952], ["id": 4, "authorId": 4, "title": "New York 2140", "year": 2017]),
                    (["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952], ["id": 5, "authorId": 4, "title": "2312", "year": 2012]),
                    (["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952], ["id": 6, "authorId": 4, "title": "Blue Mars", "year": 1996]),
                    (["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952], ["id": 7, "authorId": 4, "title": "Green Mars", "year": 1994]),
                    (["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952], ["id": 8, "authorId": 4, "title": "Red Mars", "year": 1993]),
                    (["id": 2, "name": "J. M. Coetzee", "birthYear": 1940], ["id": 1, "authorId": 2, "title": "Foe", "year": 1986]),
                    (["id": 2, "name": "J. M. Coetzee", "birthYear": 1940], ["id": 2, "authorId": 2, "title": "Three Stories", "year": 2014]),
                    (["id": 3, "name": "Herman Melville", "birthYear": 1819], ["id": 3, "authorId": 3, "title": "Moby-Dick", "year": 1851]),
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
                    .joined(with: Author.books.filter(Column("year") < 2000))
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"left\".*, \"right\".* FROM \"authors\" AS \"left\" JOIN \"books\" AS \"right\" ON ((\"right\".\"authorId\" = \"left\".\"id\") AND (\"right\".\"year\" < 2000))")
                
                assertMatch(graph, [
                    (["id": 2, "name": "J. M. Coetzee", "birthYear": 1940], ["id": 1, "authorId": 2, "title": "Foe", "year": 1986]),
                    (["id": 3, "name": "Herman Melville", "birthYear": 1819], ["id": 3, "authorId": 3, "title": "Moby-Dick", "year": 1851]),
                    (["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952], ["id": 6, "authorId": 4, "title": "Blue Mars", "year": 1996]),
                    (["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952], ["id": 7, "authorId": 4, "title": "Green Mars", "year": 1994]),
                    (["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952], ["id": 8, "authorId": 4, "title": "Red Mars", "year": 1993]),
                    ])
            }
            
            do {
                // ordered books
                let graph = try Author
                    .joined(with: Author.books.order(Column("title")))
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"left\".*, \"right\".* FROM \"authors\" AS \"left\" JOIN \"books\" AS \"right\" ON (\"right\".\"authorId\" = \"left\".\"id\") ORDER BY \"right\".\"title\"")
                
                assertMatch(graph, [
                    (["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952], ["id": 5, "authorId": 4, "title": "2312", "year": 2012]),
                    (["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952], ["id": 6, "authorId": 4, "title": "Blue Mars", "year": 1996]),
                    (["id": 2, "name": "J. M. Coetzee", "birthYear": 1940], ["id": 1, "authorId": 2, "title": "Foe", "year": 1986]),
                    (["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952], ["id": 7, "authorId": 4, "title": "Green Mars", "year": 1994]),
                    (["id": 3, "name": "Herman Melville", "birthYear": 1819], ["id": 3, "authorId": 3, "title": "Moby-Dick", "year": 1851]),
                    (["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952], ["id": 4, "authorId": 4, "title": "New York 2140", "year": 2017]),
                    (["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952], ["id": 8, "authorId": 4, "title": "Red Mars", "year": 1993]),
                    (["id": 2, "name": "J. M. Coetzee", "birthYear": 1940], ["id": 2, "authorId": 2, "title": "Three Stories", "year": 2014]),
                    ])
            }
        }
    }
}
