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
            XCTAssertEqual(sqlQueries[sqlQueries.count - 1], "SELECT \"citizenships\".\"countryCode\", \"persons\".* FROM \"persons\" JOIN \"citizenships\" ON ((\"citizenships\".\"personId\" = \"persons\".\"id\") AND (\"citizenships\".\"countryCode\" IN ('FR', 'US', 'DE')))")
            
            assertMatch(graph, [
                (["code": "FR", "name": "France"], [
                    ["id": 1, "name": "Arthur"],
                    ["id": 2, "name": "Barbara"],
                    ]),
                (["code": "US", "name": "United States"], [
                    ["id": 2, "name": "Barbara"],
                    ["id": 3, "name": "Craig"],
                    ]),
                (["code": "DE", "name": "Germany"], []),
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
                    .filter(Column("code") != "FR")
                    .including(Country.citizens)
                    .fetchAll(db)
                
                XCTAssertEqual(sqlQueries[sqlQueries.count - 2], "SELECT * FROM \"countries\" WHERE (\"code\" <> 'FR')")
                XCTAssertEqual(sqlQueries[sqlQueries.count - 1], "SELECT \"citizenships\".\"countryCode\", \"persons\".* FROM \"persons\" JOIN \"citizenships\" ON ((\"citizenships\".\"personId\" = \"persons\".\"id\") AND (\"citizenships\".\"countryCode\" IN ('US', 'DE')))")
                
                assertMatch(graph, [
                    (["code": "US", "name": "United States"], [
                        ["id": 2, "name": "Barbara"],
                        ["id": 3, "name": "Craig"],
                        ]),
                    (["code": "DE", "name": "Germany"], []),
                    ])
            }
            
            do {
                // filter after
                let graph = try Country
                    .including(Country.citizens)
                    .filter(Column("code") != "FR")
                    .fetchAll(db)
                
                XCTAssertEqual(sqlQueries[sqlQueries.count - 2], "SELECT * FROM \"countries\" WHERE (\"code\" <> 'FR')")
                XCTAssertEqual(sqlQueries[sqlQueries.count - 1], "SELECT \"citizenships\".\"countryCode\", \"persons\".* FROM \"persons\" JOIN \"citizenships\" ON ((\"citizenships\".\"personId\" = \"persons\".\"id\") AND (\"citizenships\".\"countryCode\" IN ('US', 'DE')))")
                
                assertMatch(graph, [
                    (["code": "US", "name": "United States"], [
                        ["id": 2, "name": "Barbara"],
                        ["id": 3, "name": "Craig"],
                        ]),
                    (["code": "DE", "name": "Germany"], []),
                    ])
            }
            
            do {
                // order before including
                let graph = try Country
                    .order(Column("name").desc)
                    .including(Country.citizens)
                    .fetchAll(db)
                
                XCTAssertEqual(sqlQueries[sqlQueries.count - 2], "SELECT * FROM \"countries\" ORDER BY \"name\" DESC")
                XCTAssertEqual(sqlQueries[sqlQueries.count - 1], "SELECT \"citizenships\".\"countryCode\", \"persons\".* FROM \"persons\" JOIN \"citizenships\" ON ((\"citizenships\".\"personId\" = \"persons\".\"id\") AND (\"citizenships\".\"countryCode\" IN ('US', 'DE', 'FR')))")
                
                assertMatch(graph, [
                    (["code": "US", "name": "United States"], [
                        ["id": 2, "name": "Barbara"],
                        ["id": 3, "name": "Craig"],
                        ]),
                    (["code": "DE", "name": "Germany"], []),
                    (["code": "FR", "name": "France"], [
                        ["id": 1, "name": "Arthur"],
                        ["id": 2, "name": "Barbara"],
                        ]),
                    ])
            }
            
            do {
                // order after including
                let graph = try Country
                    .including(Country.citizens)
                    .order(Column("name").desc)
                    .fetchAll(db)
                
                XCTAssertEqual(sqlQueries[sqlQueries.count - 2], "SELECT * FROM \"countries\" ORDER BY \"name\" DESC")
                XCTAssertEqual(sqlQueries[sqlQueries.count - 1], "SELECT \"citizenships\".\"countryCode\", \"persons\".* FROM \"persons\" JOIN \"citizenships\" ON ((\"citizenships\".\"personId\" = \"persons\".\"id\") AND (\"citizenships\".\"countryCode\" IN ('US', 'DE', 'FR')))")
                
                assertMatch(graph, [
                    (["code": "US", "name": "United States"], [
                        ["id": 2, "name": "Barbara"],
                        ["id": 3, "name": "Craig"],
                        ]),
                    (["code": "DE", "name": "Germany"], []),
                    (["code": "FR", "name": "France"], [
                        ["id": 1, "name": "Arthur"],
                        ["id": 2, "name": "Barbara"],
                        ]),
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
                    .including(Country.citizens.filter(Column("name") != "Craig"))
                    .fetchAll(db)
                
                XCTAssertEqual(sqlQueries[sqlQueries.count - 2], "SELECT * FROM \"countries\"")
                XCTAssertEqual(sqlQueries[sqlQueries.count - 1], "SELECT \"citizenships\".\"countryCode\", \"persons\".* FROM \"persons\" JOIN \"citizenships\" ON ((\"citizenships\".\"personId\" = \"persons\".\"id\") AND (\"citizenships\".\"countryCode\" IN ('FR', 'US', 'DE'))) WHERE (\"persons\".\"name\" <> 'Craig')")
                
                assertMatch(graph, [
                    (["code": "FR", "name": "France"], [
                        ["id": 1, "name": "Arthur"],
                        ["id": 2, "name": "Barbara"],
                        ]),
                    (["code": "US", "name": "United States"], [
                        ["id": 2, "name": "Barbara"],
                        ]),
                    (["code": "DE", "name": "Germany"], []),
                    ])
            }
            
            do {
                // ordered citizens
                let graph = try Country
                    .including(Country.citizens.order(Column("name").desc))
                    .fetchAll(db)
                
                XCTAssertEqual(sqlQueries[sqlQueries.count - 2], "SELECT * FROM \"countries\"")
                XCTAssertEqual(sqlQueries[sqlQueries.count - 1], "SELECT \"citizenships\".\"countryCode\", \"persons\".* FROM \"persons\" JOIN \"citizenships\" ON ((\"citizenships\".\"personId\" = \"persons\".\"id\") AND (\"citizenships\".\"countryCode\" IN ('FR', 'US', 'DE'))) ORDER BY \"persons\".\"name\" DESC")
                
                assertMatch(graph, [
                    (["code": "FR", "name": "France"], [
                        ["id": 2, "name": "Barbara"],
                        ["id": 1, "name": "Arthur"],
                        ]),
                    (["code": "US", "name": "United States"], [
                        ["id": 3, "name": "Craig"],
                        ["id": 2, "name": "Barbara"],
                        ]),
                    (["code": "DE", "name": "Germany"], []),
                    ])
            }
        }
    }
    
    func testHavingAnnotationIncluding() throws {
        let dbQueue = try makeDatabaseQueue()
        try HasManyThroughAssociationHasManyBelongsToFixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            do {
                // filter before
                let graph = try Country
                    .filter(Country.citizens.count == 2) // TODO: test for another hasManyThrough annotation, and for a hasMany annotation
                    .including(Country.citizens)
                    .fetchAll(db)
                
                XCTAssertEqual(sqlQueries[sqlQueries.count - 2], "SELECT \"countries\".* FROM \"countries\" LEFT JOIN \"citizenships\" ON (\"citizenships\".\"countryCode\" = \"countries\".\"code\") LEFT JOIN \"persons\" ON (\"persons\".\"id\" = \"citizenships\".\"personId\") GROUP BY \"countries\".\"code\" HAVING (COUNT(\"persons\".\"id\") = 2)")
                XCTAssertEqual(sqlQueries[sqlQueries.count - 1], "SELECT \"citizenships\".\"countryCode\", \"persons\".* FROM \"persons\" JOIN \"citizenships\" ON ((\"citizenships\".\"personId\" = \"persons\".\"id\") AND (\"citizenships\".\"countryCode\" IN ('FR', 'US')))")
                
                assertMatch(graph, [
                    (["code": "FR", "name": "France"], [
                        ["id": 1, "name": "Arthur"],
                        ["id": 2, "name": "Barbara"],
                        ]),
                    (["code": "US", "name": "United States"], [
                        ["id": 2, "name": "Barbara"],
                        ["id": 3, "name": "Craig"],
                        ]),
                    ])
            }
            do {
                // filter after
                let graph = try Country
                    .including(Country.citizens)
                    .filter(Country.citizens.count == 2)
                    .fetchAll(db)
                
                XCTAssertEqual(sqlQueries[sqlQueries.count - 2], "SELECT \"countries\".* FROM \"countries\" LEFT JOIN \"citizenships\" ON (\"citizenships\".\"countryCode\" = \"countries\".\"code\") LEFT JOIN \"persons\" ON (\"persons\".\"id\" = \"citizenships\".\"personId\") GROUP BY \"countries\".\"code\" HAVING (COUNT(\"persons\".\"id\") = 2)")
                XCTAssertEqual(sqlQueries[sqlQueries.count - 1], "SELECT \"citizenships\".\"countryCode\", \"persons\".* FROM \"persons\" JOIN \"citizenships\" ON ((\"citizenships\".\"personId\" = \"persons\".\"id\") AND (\"citizenships\".\"countryCode\" IN ('FR', 'US')))")
                
                assertMatch(graph, [
                    (["code": "FR", "name": "France"], [
                        ["id": 1, "name": "Arthur"],
                        ["id": 2, "name": "Barbara"],
                        ]),
                    (["code": "US", "name": "United States"], [
                        ["id": 2, "name": "Barbara"],
                        ["id": 3, "name": "Craig"],
                        ]),
                    ])
            }
        }
    }
}
