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

class HasManyThroughAssociationHasManyBelongsToLeftJoinedTests: GRDBTestCase {
    
    // TODO: conditions on middle table
    
    func testSimplestRequest() throws {
        let dbQueue = try makeDatabaseQueue()
        try HasManyThroughAssociationHasManyBelongsToFixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            let graph = try Country
                .leftJoined(with: Country.citizens)
                .fetchAll(db)
            
            XCTAssertEqual(lastSQLQuery, "SELECT \"countries\".*, \"persons\".* FROM \"countries\" LEFT JOIN \"citizenships\" ON (\"citizenships\".\"countryCode\" = \"countries\".\"code\") LEFT JOIN \"persons\" ON (\"persons\".\"id\" = \"citizenships\".\"personId\")")
            
            assertMatch(graph, [
                (["code": "FR", "name": "France"], ["id": 1, "name": "Arthur"]),
                (["code": "FR", "name": "France"], ["id": 2, "name": "Barbara"]),
                (["code": "US", "name": "United States"], ["id": 2, "name": "Barbara"]),
                (["code": "US", "name": "United States"], ["id": 3, "name": "Craig"]),
                (["code": "DE", "name": "Germany"], nil),
                ])
        }
    }
    
    func testLeftRequestDerivation() throws {
        let dbQueue = try makeDatabaseQueue()
        try HasManyThroughAssociationHasManyBelongsToFixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            do {
                // filter before joined
                let graph = try Country
                    .filter(Column("code") != "FR")
                    .leftJoined(with: Country.citizens)
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"countries\".*, \"persons\".* FROM \"countries\" LEFT JOIN \"citizenships\" ON (\"citizenships\".\"countryCode\" = \"countries\".\"code\") LEFT JOIN \"persons\" ON (\"persons\".\"id\" = \"citizenships\".\"personId\") WHERE (\"countries\".\"code\" <> 'FR')")
                
                assertMatch(graph, [
                    (["code": "US", "name": "United States"], ["id": 2, "name": "Barbara"]),
                    (["code": "US", "name": "United States"], ["id": 3, "name": "Craig"]),
                    (["code": "DE", "name": "Germany"], nil),
                    ])
            }
            
            do {
                // filter after joined
                let graph = try Country
                    .leftJoined(with: Country.citizens)
                    .filter(Column("code") != "FR")
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"countries\".*, \"persons\".* FROM \"countries\" LEFT JOIN \"citizenships\" ON (\"citizenships\".\"countryCode\" = \"countries\".\"code\") LEFT JOIN \"persons\" ON (\"persons\".\"id\" = \"citizenships\".\"personId\") WHERE (\"countries\".\"code\" <> 'FR')")
                
                assertMatch(graph, [
                    (["code": "US", "name": "United States"], ["id": 2, "name": "Barbara"]),
                    (["code": "US", "name": "United States"], ["id": 3, "name": "Craig"]),
                    (["code": "DE", "name": "Germany"], nil),
                    ])
            }
            
            do {
                // order before joined
                let graph = try Country
                    .order(Column("name").desc)
                    .leftJoined(with: Country.citizens)
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"countries\".*, \"persons\".* FROM \"countries\" LEFT JOIN \"citizenships\" ON (\"citizenships\".\"countryCode\" = \"countries\".\"code\") LEFT JOIN \"persons\" ON (\"persons\".\"id\" = \"citizenships\".\"personId\") ORDER BY \"countries\".\"name\" DESC")
                
                assertMatch(graph, [
                    (["code": "US", "name": "United States"], ["id": 2, "name": "Barbara"]),
                    (["code": "US", "name": "United States"], ["id": 3, "name": "Craig"]),
                    (["code": "DE", "name": "Germany"], nil),
                    (["code": "FR", "name": "France"], ["id": 1, "name": "Arthur"]),
                    (["code": "FR", "name": "France"], ["id": 2, "name": "Barbara"]),
                    ])
            }
            
            do {
                // order after joined
                let graph = try Country
                    .leftJoined(with: Country.citizens)
                    .order(Column("name").desc)
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"countries\".*, \"persons\".* FROM \"countries\" LEFT JOIN \"citizenships\" ON (\"citizenships\".\"countryCode\" = \"countries\".\"code\") LEFT JOIN \"persons\" ON (\"persons\".\"id\" = \"citizenships\".\"personId\") ORDER BY \"countries\".\"name\" DESC")
                
                assertMatch(graph, [
                    (["code": "US", "name": "United States"], ["id": 2, "name": "Barbara"]),
                    (["code": "US", "name": "United States"], ["id": 3, "name": "Craig"]),
                    (["code": "DE", "name": "Germany"], nil),
                    (["code": "FR", "name": "France"], ["id": 1, "name": "Arthur"]),
                    (["code": "FR", "name": "France"], ["id": 2, "name": "Barbara"]),
                    ])
            }
        }
    }
    
    func testRightRequestDerivation() throws {
        let dbQueue = try makeDatabaseQueue()
        try HasManyThroughAssociationHasManyBelongsToFixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            do {
                // filtered persons
                let graph = try Country
                    .leftJoined(with: Country.citizens.filter(Column("name") != "Craig"))
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"countries\".*, \"persons\".* FROM \"countries\" LEFT JOIN \"citizenships\" ON (\"citizenships\".\"countryCode\" = \"countries\".\"code\") LEFT JOIN \"persons\" ON ((\"persons\".\"id\" = \"citizenships\".\"personId\") AND (\"persons\".\"name\" <> 'Craig'))")
                
                assertMatch(graph, [
                    (["code": "FR", "name": "France"], ["id": 1, "name": "Arthur"]),
                    (["code": "FR", "name": "France"], ["id": 2, "name": "Barbara"]),
                    (["code": "US", "name": "United States"], ["id": 2, "name": "Barbara"]),
                    (["code": "US", "name": "United States"], nil), // TODO: this is inconsistent with HasManyAssociationLeftJoinedRequest. Possible fix: don't allow non-null citizenship with null citizen
                    (["code": "DE", "name": "Germany"], nil),
                    ])
            }
            
            do {
                // ordered persons
                let graph = try Country
                    .leftJoined(with: Country.citizens.order(Column("name").desc))
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"countries\".*, \"persons\".* FROM \"countries\" LEFT JOIN \"citizenships\" ON (\"citizenships\".\"countryCode\" = \"countries\".\"code\") LEFT JOIN \"persons\" ON (\"persons\".\"id\" = \"citizenships\".\"personId\") ORDER BY \"persons\".\"name\" DESC")
                
                assertMatch(graph, [
                    (["code": "US", "name": "United States"], ["id": 3, "name": "Craig"]),
                    (["code": "FR", "name": "France"], ["id": 2, "name": "Barbara"]),
                    (["code": "US", "name": "United States"], ["id": 2, "name": "Barbara"]),
                    (["code": "FR", "name": "France"], ["id": 1, "name": "Arthur"]),
                    (["code": "DE", "name": "Germany"], nil),
                    ])
            }
        }
    }
}
