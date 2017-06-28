import XCTest
#if GRDBCIPHER
    import GRDBCipher
#elseif GRDBCUSTOMSQLITE
    import GRDBCustomSQLite
#else
    import GRDB
#endif

private typealias Reader = HasManyThrough_BelongsTo_HasMany_Fixture.Reader
private typealias Book = HasManyThrough_BelongsTo_HasMany_Fixture.Book

class HasManyThroughRightRequest_BelongsTo_HasMany_Tests: GRDBTestCase {
    
    // TODO: conditions on middle table
    
//    func testRequest() throws {
//        let dbQueue = try makeDatabaseQueue()
//        try HasManyThrough_BelongsTo_HasMany_Fixture().migrator.migrate(dbQueue)
//        
//        try dbQueue.inDatabase { db in
//
//            do {
//                let reader = try Reader.fetchOne(db, key: "FR")!
//                let request = reader.makeRequest(Reader.books)
//                let books = try request.fetchAll(db)
//                XCTAssertEqual(lastSQLQuery, "SELECT \"books\".* FROM \"books\" JOIN \"bookships\" ON ((\"bookships\".\"bookId\" = \"books\".\"id\") AND (\"bookships\".\"readerCode\" = \'FR\'))")
//                assertMatch(books, [
//                    ["id": 1, "name": "Arthur"],
//                    ["id": 2, "name": "Barbara"],
//                    ])
//            }
//            
//            do {
//                let reader = try Reader.fetchOne(db, key: "US")!
//                let request = reader.makeRequest(Reader.books)
//                let books = try request.fetchAll(db)
//                XCTAssertEqual(lastSQLQuery, "SELECT \"books\".* FROM \"books\" JOIN \"bookships\" ON ((\"bookships\".\"bookId\" = \"books\".\"id\") AND (\"bookships\".\"readerCode\" = \'US\'))")
//                assertMatch(books, [
//                    ["id": 2, "name": "Barbara"],
//                    ["id": 3, "name": "Craig"],
//                    ])
//            }
//            
//            do {
//                let reader = try Reader.fetchOne(db, key: "DE")!
//                let request = reader.makeRequest(Reader.books)
//                let books = try request.fetchAll(db)
//                XCTAssertEqual(lastSQLQuery, "SELECT \"books\".* FROM \"books\" JOIN \"bookships\" ON ((\"bookships\".\"bookId\" = \"books\".\"id\") AND (\"bookships\".\"readerCode\" = \'DE\'))")
//                XCTAssertTrue(books.isEmpty)
//            }
//            
//            do {
//                let reader = try Reader.fetchOne(db, key: "US")!
//                let request = reader.makeRequest(Reader.books).filter(Column("name") != "Craig")
//                let books = try request.fetchAll(db)
//                XCTAssertEqual(lastSQLQuery, "SELECT \"books\".* FROM \"books\" JOIN \"bookships\" ON ((\"bookships\".\"bookId\" = \"books\".\"id\") AND (\"bookships\".\"readerCode\" = \'US\')) WHERE (\"books\".\"name\" <> \'Craig\')")
//                assertMatch(books, [
//                    ["id": 2, "name": "Barbara"],
//                    ])
//            }
//            
//            do {
//                let reader = try Reader.fetchOne(db, key: "US")!
//                let request = reader.makeRequest(Reader.books).order(Column("name").desc)
//                let books = try request.fetchAll(db)
//                XCTAssertEqual(lastSQLQuery, "SELECT \"books\".* FROM \"books\" JOIN \"bookships\" ON ((\"bookships\".\"bookId\" = \"books\".\"id\") AND (\"bookships\".\"readerCode\" = \'US\')) ORDER BY \"books\".\"name\" DESC")
//                assertMatch(books, [
//                    ["id": 3, "name": "Craig"],
//                    ["id": 2, "name": "Barbara"],
//                    ])
//            }
//        }
//    }
//    
//    func testFetchAll() throws {
//        let dbQueue = try makeDatabaseQueue()
//        try HasManyThrough_BelongsTo_HasMany_Fixture().migrator.migrate(dbQueue)
//        
//        try dbQueue.inDatabase { db in
//            
//            do {
//                let reader = try Reader.fetchOne(db, key: "FR")!
//                let books = try reader.fetchAll(db, Reader.books)
//                XCTAssertEqual(lastSQLQuery, "SELECT \"books\".* FROM \"books\" JOIN \"bookships\" ON ((\"bookships\".\"bookId\" = \"books\".\"id\") AND (\"bookships\".\"readerCode\" = \'FR\'))")
//                assertMatch(books, [
//                    ["id": 1, "name": "Arthur"],
//                    ["id": 2, "name": "Barbara"],
//                    ])
//            }
//            
//            do {
//                let reader = try Reader.fetchOne(db, key: "US")!
//                let books = try reader.fetchAll(db, Reader.books)
//                XCTAssertEqual(lastSQLQuery, "SELECT \"books\".* FROM \"books\" JOIN \"bookships\" ON ((\"bookships\".\"bookId\" = \"books\".\"id\") AND (\"bookships\".\"readerCode\" = \'US\'))")
//                assertMatch(books, [
//                    ["id": 2, "name": "Barbara"],
//                    ["id": 3, "name": "Craig"],
//                    ])
//            }
//            
//            do {
//                let reader = try Reader.fetchOne(db, key: "DE")!
//                let books = try reader.fetchAll(db, Reader.books)
//                XCTAssertEqual(lastSQLQuery, "SELECT \"books\".* FROM \"books\" JOIN \"bookships\" ON ((\"bookships\".\"bookId\" = \"books\".\"id\") AND (\"bookships\".\"readerCode\" = \'DE\'))")
//                XCTAssertTrue(books.isEmpty)
//            }
//            
//            do {
//                let reader = try Reader.fetchOne(db, key: "US")!
//                let books = try reader.fetchAll(db, Reader.books.filter(Column("name") != "Craig"))
//                XCTAssertEqual(lastSQLQuery, "SELECT \"books\".* FROM \"books\" JOIN \"bookships\" ON ((\"bookships\".\"bookId\" = \"books\".\"id\") AND (\"bookships\".\"readerCode\" = \'US\')) WHERE (\"books\".\"name\" <> \'Craig\')")
//                assertMatch(books, [
//                    ["id": 2, "name": "Barbara"],
//                    ])
//            }
//            
//            do {
//                let reader = try Reader.fetchOne(db, key: "US")!
//                let books = try reader.fetchAll(db, Reader.books.order(Column("name").desc))
//                XCTAssertEqual(lastSQLQuery, "SELECT \"books\".* FROM \"books\" JOIN \"bookships\" ON ((\"bookships\".\"bookId\" = \"books\".\"id\") AND (\"bookships\".\"readerCode\" = \'US\')) ORDER BY \"books\".\"name\" DESC")
//                assertMatch(books, [
//                    ["id": 3, "name": "Craig"],
//                    ["id": 2, "name": "Barbara"],
//                    ])
//            }
//        }
//    }
}
