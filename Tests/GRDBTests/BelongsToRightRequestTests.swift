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

class BelongsToRightRequestTests: GRDBTestCase {
    
    func testRequest() throws {
        let dbQueue = try makeDatabaseQueue()
        try AssociationFixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            
            do {
                let book = try Book.fetchOne(db, key: 1)!
                let request = book.makeRequest(Book.author)
                let author = try request.fetchOne(db)
                XCTAssertEqual(lastSQLQuery, "SELECT * FROM \"authors\" WHERE (\"id\" = 2)")
                assertMatch(author, ["id": 2, "name": "J. M. Coetzee", "birthYear": 1940])
            }
            
            do {
                let book = try Book.fetchOne(db, key: 9)!
                let request = book.makeRequest(Book.author)
                let author = try request.fetchOne(db)
                XCTAssertEqual(lastSQLQuery, "SELECT * FROM \"authors\" WHERE (\"id\" IS NULL)")
                XCTAssertNil(author)
            }
        }
    }
    
    func testFetchOne() throws {
        let dbQueue = try makeDatabaseQueue()
        try AssociationFixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            
            do {
                // TODO: way to make the author non-optional?
                let book = try Book.fetchOne(db, key: 1)!
                let author = try book.fetchOne(db, Book.author)
                XCTAssertEqual(lastSQLQuery, "SELECT * FROM \"authors\" WHERE (\"id\" = 2)")
                assertMatch(author, ["id": 2, "name": "J. M. Coetzee", "birthYear": 1940])
            }
            
            do {
                let book = try Book.fetchOne(db, key: 9)!
                let author = try book.fetchOne(db, Book.author)
                XCTAssertEqual(lastSQLQuery, "SELECT * FROM \"authors\" WHERE (\"id\" IS NULL)")
                XCTAssertNil(author)
            }
        }
    }
}
