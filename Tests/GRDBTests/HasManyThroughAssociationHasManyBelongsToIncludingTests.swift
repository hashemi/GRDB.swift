import XCTest
#if GRDBCIPHER
    import GRDBCipher
#elseif GRDBCUSTOMSQLITE
    import GRDBCustomSQLite
#else
    import GRDB
#endif

private typealias Country = HasManyThroughAssociationHasManyBelongsToFixture.Country
private typealias Person = HasManyThroughAssociationHasManyBelongsToFixture.Person

class HasManyThroughAssociationHasManyBelongsToIncludingTests: GRDBTestCase {
    
    // TODO: conditions on middle table
    
    func testSimplestRequest() throws {
        let dbQueue = try makeDatabaseQueue()
        try HasManyThroughAssociationHasManyBelongsToFixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            let graph = try Country
                .including(Country.citizens)
                .fetchAll(db)
            
            XCTAssertEqual(sqlQueries[sqlQueries.count - 2], "SELECT * FROM \"countries\"")
            XCTAssertEqual(sqlQueries[sqlQueries.count - 1], "SELECT * FROM \"citizens\" WHERE (\"countryCode\" IN (1, 2, 3, 4))")
            
            assertMatch(graph, [
                (["id": 1, "name": "Gwendal Roué", "birthYear": 1973], []),
                (["id": 2, "name": "J. M. Coetzee", "birthYear": 1940], [
                    ["id": 1, "countryCode": 2, "title": "Foe", "year": 1986],
                    ["id": 2, "countryCode": 2, "title": "Three Stories", "year": 2014],
                    ]),
                (["id": 3, "name": "Herman Melville", "birthYear": 1819], [
                    ["id": 3, "countryCode": 3, "title": "Moby-Dick", "year": 1851],
                    ]),
                (["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952], [
                    ["id": 4, "countryCode": 4, "title": "New York 2140", "year": 2017],
                    ["id": 5, "countryCode": 4, "title": "2312", "year": 2012],
                    ["id": 6, "countryCode": 4, "title": "Blue Mars", "year": 1996],
                    ["id": 7, "countryCode": 4, "title": "Green Mars", "year": 1994],
                    ["id": 8, "countryCode": 4, "title": "Red Mars", "year": 1993],
                    ]),
                ])
        }
    }
    
    func testLeftRequestDerivation() throws {
        let dbQueue = try makeDatabaseQueue()
        try HasManyThroughAssociationHasManyBelongsToFixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            do {
                // filter before
                let graph = try Country
                    .filter(Column("birthYear") >= 1900)
                    .including(Country.citizens)
                    .fetchAll(db)
                
                XCTAssertEqual(sqlQueries[sqlQueries.count - 2], "SELECT * FROM \"countries\" WHERE (\"birthYear\" >= 1900)")
                XCTAssertEqual(sqlQueries[sqlQueries.count - 1], "SELECT * FROM \"citizens\" WHERE (\"countryCode\" IN (1, 2, 4))")
                
                assertMatch(graph, [
                    (["id": 1, "name": "Gwendal Roué", "birthYear": 1973], []),
                    (["id": 2, "name": "J. M. Coetzee", "birthYear": 1940], [
                        ["id": 1, "countryCode": 2, "title": "Foe", "year": 1986],
                        ["id": 2, "countryCode": 2, "title": "Three Stories", "year": 2014],
                        ]),
                    (["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952], [
                        ["id": 4, "countryCode": 4, "title": "New York 2140", "year": 2017],
                        ["id": 5, "countryCode": 4, "title": "2312", "year": 2012],
                        ["id": 6, "countryCode": 4, "title": "Blue Mars", "year": 1996],
                        ["id": 7, "countryCode": 4, "title": "Green Mars", "year": 1994],
                        ["id": 8, "countryCode": 4, "title": "Red Mars", "year": 1993],
                        ]),
                    ])
            }
            
            do {
                // filter after
                let graph = try Country
                    .including(Country.citizens)
                    .filter(Column("birthYear") >= 1900)
                    .fetchAll(db)
                
                XCTAssertEqual(sqlQueries[sqlQueries.count - 2], "SELECT * FROM \"countries\" WHERE (\"birthYear\" >= 1900)")
                XCTAssertEqual(sqlQueries[sqlQueries.count - 1], "SELECT * FROM \"citizens\" WHERE (\"countryCode\" IN (1, 2, 4))")
                
                assertMatch(graph, [
                    (["id": 1, "name": "Gwendal Roué", "birthYear": 1973], []),
                    (["id": 2, "name": "J. M. Coetzee", "birthYear": 1940], [
                        ["id": 1, "countryCode": 2, "title": "Foe", "year": 1986],
                        ["id": 2, "countryCode": 2, "title": "Three Stories", "year": 2014],
                        ]),
                    (["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952], [
                        ["id": 4, "countryCode": 4, "title": "New York 2140", "year": 2017],
                        ["id": 5, "countryCode": 4, "title": "2312", "year": 2012],
                        ["id": 6, "countryCode": 4, "title": "Blue Mars", "year": 1996],
                        ["id": 7, "countryCode": 4, "title": "Green Mars", "year": 1994],
                        ["id": 8, "countryCode": 4, "title": "Red Mars", "year": 1993],
                        ]),
                    ])
            }
            
            do {
                // order before including
                let graph = try Country
                    .order(Column("name").desc)
                    .including(Country.citizens)
                    .fetchAll(db)
                
                XCTAssertEqual(sqlQueries[sqlQueries.count - 2], "SELECT * FROM \"countries\" ORDER BY \"name\" DESC")
                XCTAssertEqual(sqlQueries[sqlQueries.count - 1], "SELECT * FROM \"citizens\" WHERE (\"countryCode\" IN (4, 2, 3, 1))")
                
                assertMatch(graph, [
                    (["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952], [
                        ["id": 4, "countryCode": 4, "title": "New York 2140", "year": 2017],
                        ["id": 5, "countryCode": 4, "title": "2312", "year": 2012],
                        ["id": 6, "countryCode": 4, "title": "Blue Mars", "year": 1996],
                        ["id": 7, "countryCode": 4, "title": "Green Mars", "year": 1994],
                        ["id": 8, "countryCode": 4, "title": "Red Mars", "year": 1993],
                        ]),
                    (["id": 2, "name": "J. M. Coetzee", "birthYear": 1940], [
                        ["id": 1, "countryCode": 2, "title": "Foe", "year": 1986],
                        ["id": 2, "countryCode": 2, "title": "Three Stories", "year": 2014],
                        ]),
                    (["id": 3, "name": "Herman Melville", "birthYear": 1819], [
                        ["id": 3, "countryCode": 3, "title": "Moby-Dick", "year": 1851],
                        ]),
                    (["id": 1, "name": "Gwendal Roué", "birthYear": 1973], []),
                    ])
            }
            
            do {
                // order after including
                let graph = try Country
                    .including(Country.citizens)
                    .order(Column("name").desc)
                    .fetchAll(db)
                
                XCTAssertEqual(sqlQueries[sqlQueries.count - 2], "SELECT * FROM \"countries\" ORDER BY \"name\" DESC")
                XCTAssertEqual(sqlQueries[sqlQueries.count - 1], "SELECT * FROM \"citizens\" WHERE (\"countryCode\" IN (4, 2, 3, 1))")
                
                assertMatch(graph, [
                    (["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952], [
                        ["id": 4, "countryCode": 4, "title": "New York 2140", "year": 2017],
                        ["id": 5, "countryCode": 4, "title": "2312", "year": 2012],
                        ["id": 6, "countryCode": 4, "title": "Blue Mars", "year": 1996],
                        ["id": 7, "countryCode": 4, "title": "Green Mars", "year": 1994],
                        ["id": 8, "countryCode": 4, "title": "Red Mars", "year": 1993],
                        ]),
                    (["id": 2, "name": "J. M. Coetzee", "birthYear": 1940], [
                        ["id": 1, "countryCode": 2, "title": "Foe", "year": 1986],
                        ["id": 2, "countryCode": 2, "title": "Three Stories", "year": 2014],
                        ]),
                    (["id": 3, "name": "Herman Melville", "birthYear": 1819], [
                        ["id": 3, "countryCode": 3, "title": "Moby-Dick", "year": 1851],
                        ]),
                    (["id": 1, "name": "Gwendal Roué", "birthYear": 1973], []),
                    ])
            }
        }
    }
    
    func testRightRequestDerivation() throws {
        let dbQueue = try makeDatabaseQueue()
        try HasManyThroughAssociationHasManyBelongsToFixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            do {
                // filtered citizens
                let graph = try Country
                    .including(Country.citizens.filter(Column("year") < 2000))
                    .fetchAll(db)
                
                XCTAssertEqual(sqlQueries[sqlQueries.count - 2], "SELECT * FROM \"countries\"")
                XCTAssertEqual(sqlQueries[sqlQueries.count - 1], "SELECT * FROM \"citizens\" WHERE ((\"year\" < 2000) AND (\"countryCode\" IN (1, 2, 3, 4)))")
                
                assertMatch(graph, [
                    (["id": 1, "name": "Gwendal Roué", "birthYear": 1973], []),
                    (["id": 2, "name": "J. M. Coetzee", "birthYear": 1940], [
                        ["id": 1, "countryCode": 2, "title": "Foe", "year": 1986],
                        ]),
                    (["id": 3, "name": "Herman Melville", "birthYear": 1819], [
                        ["id": 3, "countryCode": 3, "title": "Moby-Dick", "year": 1851],
                        ]),
                    (["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952], [
                        ["id": 6, "countryCode": 4, "title": "Blue Mars", "year": 1996],
                        ["id": 7, "countryCode": 4, "title": "Green Mars", "year": 1994],
                        ["id": 8, "countryCode": 4, "title": "Red Mars", "year": 1993],
                        ]),
                    ])
            }
            
            do {
                // ordered citizens
                let graph = try Country
                    .including(Country.citizens.order(Column("title")))
                    .fetchAll(db)
                
                XCTAssertEqual(sqlQueries[sqlQueries.count - 2], "SELECT * FROM \"countries\"")
                XCTAssertEqual(sqlQueries[sqlQueries.count - 1], "SELECT * FROM \"citizens\" WHERE (\"countryCode\" IN (1, 2, 3, 4)) ORDER BY \"title\"")
                
                assertMatch(graph, [
                    (["id": 1, "name": "Gwendal Roué", "birthYear": 1973], []),
                    (["id": 2, "name": "J. M. Coetzee", "birthYear": 1940], [
                        ["id": 1, "countryCode": 2, "title": "Foe", "year": 1986],
                        ["id": 2, "countryCode": 2, "title": "Three Stories", "year": 2014],
                        ]),
                    (["id": 3, "name": "Herman Melville", "birthYear": 1819], [
                        ["id": 3, "countryCode": 3, "title": "Moby-Dick", "year": 1851],
                        ]),
                    (["id": 4, "name": "Kim Stanley Robinson", "birthYear": 1952], [
                        ["id": 5, "countryCode": 4, "title": "2312", "year": 2012],
                        ["id": 6, "countryCode": 4, "title": "Blue Mars", "year": 1996],
                        ["id": 7, "countryCode": 4, "title": "Green Mars", "year": 1994],
                        ["id": 4, "countryCode": 4, "title": "New York 2140", "year": 2017],
                        ["id": 8, "countryCode": 4, "title": "Red Mars", "year": 1993],
                        ]),
                    ])
            }
        }
    }
}
