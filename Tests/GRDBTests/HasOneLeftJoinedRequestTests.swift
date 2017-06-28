import XCTest
#if GRDBCIPHER
    import GRDBCipher
#elseif GRDBCUSTOMSQLITE
    import GRDBCustomSQLite
#else
    import GRDB
#endif

private typealias Country = AssociationFixture.Country
private typealias CountryProfile = AssociationFixture.CountryProfile

class HasOneLeftJoinedRequestTests: GRDBTestCase {
    
    func testSimplestRequest() throws {
        let dbQueue = try makeDatabaseQueue()
        try AssociationFixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            let graph = try Country
                .leftJoined(with: Country.profile)
                .fetchAll(db)
            
            XCTAssertEqual(lastSQLQuery, "SELECT \"countries\".*, \"countryProfiles\".* FROM \"countries\" LEFT JOIN \"countryProfiles\" ON (\"countryProfiles\".\"countryCode\" = \"countries\".\"code\")")
            
            assertMatch(graph, [
                (["code": "FR", "name": "France"], ["countryCode": "FR", "area": 643801, "currency": "EUR"]),
                (["code": "US", "name": "United States"], ["countryCode": "US", "area": 9833520, "currency": "USD"]),
                (["code": "DE", "name": "Germany"], ["countryCode": "DE", "area": 357168, "currency": "EUR"]),
                (["code": "AA", "name": "Atlantis"], nil),
                ])
        }
    }
    
    func testLeftRequestDerivation() throws {
        let dbQueue = try makeDatabaseQueue()
        try AssociationFixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            do {
                // filter before
                let graph = try Country
                    .filter(Column("code") != "FR")
                    .leftJoined(with: Country.profile)
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"countries\".*, \"countryProfiles\".* FROM \"countries\" LEFT JOIN \"countryProfiles\" ON (\"countryProfiles\".\"countryCode\" = \"countries\".\"code\") WHERE (\"countries\".\"code\" <> 'FR')")
                
                assertMatch(graph, [
                    (["code": "US", "name": "United States"], ["countryCode": "US", "area": 9833520, "currency": "USD"]),
                    (["code": "DE", "name": "Germany"], ["countryCode": "DE", "area": 357168, "currency": "EUR"]),
                    (["code": "AA", "name": "Atlantis"], nil),
                    ])
            }
            
            do {
                // filter after
                let graph = try Country
                    .leftJoined(with: Country.profile)
                    .filter(Column("code") != "FR")
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"countries\".*, \"countryProfiles\".* FROM \"countries\" LEFT JOIN \"countryProfiles\" ON (\"countryProfiles\".\"countryCode\" = \"countries\".\"code\") WHERE (\"countries\".\"code\" <> 'FR')")
                
                assertMatch(graph, [
                    (["code": "US", "name": "United States"], ["countryCode": "US", "area": 9833520, "currency": "USD"]),
                    (["code": "DE", "name": "Germany"], ["countryCode": "DE", "area": 357168, "currency": "EUR"]),
                    (["code": "AA", "name": "Atlantis"], nil),
                    ])
            }
            
            do {
                // order before
                let graph = try Country
                    .order(Column("code"))
                    .leftJoined(with: Country.profile)
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"countries\".*, \"countryProfiles\".* FROM \"countries\" LEFT JOIN \"countryProfiles\" ON (\"countryProfiles\".\"countryCode\" = \"countries\".\"code\") ORDER BY \"countries\".\"code\"")
                
                assertMatch(graph, [
                    (["code": "AA", "name": "Atlantis"], nil),
                    (["code": "DE", "name": "Germany"], ["countryCode": "DE", "area": 357168, "currency": "EUR"]),
                    (["code": "FR", "name": "France"], ["countryCode": "FR", "area": 643801, "currency": "EUR"]),
                    (["code": "US", "name": "United States"], ["countryCode": "US", "area": 9833520, "currency": "USD"]),
                    ])
            }
            
            do {
                // order after
                let graph = try Country
                    .leftJoined(with: Country.profile)
                    .order(Column("code"))
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"countries\".*, \"countryProfiles\".* FROM \"countries\" LEFT JOIN \"countryProfiles\" ON (\"countryProfiles\".\"countryCode\" = \"countries\".\"code\") ORDER BY \"countries\".\"code\"")
                
                assertMatch(graph, [
                    (["code": "AA", "name": "Atlantis"], nil),
                    (["code": "DE", "name": "Germany"], ["countryCode": "DE", "area": 357168, "currency": "EUR"]),
                    (["code": "FR", "name": "France"], ["countryCode": "FR", "area": 643801, "currency": "EUR"]),
                    (["code": "US", "name": "United States"], ["countryCode": "US", "area": 9833520, "currency": "USD"]),
                    ])
            }
        }
    }
    
    func testRightRequestDerivation() throws {
        let dbQueue = try makeDatabaseQueue()
        try AssociationFixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            do {
                let graph = try Country
                    .leftJoined(with: Country.profile.filter(Column("currency") == "EUR"))
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"countries\".*, \"countryProfiles\".* FROM \"countries\" LEFT JOIN \"countryProfiles\" ON ((\"countryProfiles\".\"countryCode\" = \"countries\".\"code\") AND (\"countryProfiles\".\"currency\" = \'EUR\'))")
                
                assertMatch(graph, [
                    (["code": "FR", "name": "France"], ["countryCode": "FR", "area": 643801, "currency": "EUR"]),
                    (["code": "US", "name": "United States"], nil),
                    (["code": "DE", "name": "Germany"], ["countryCode": "DE", "area": 357168, "currency": "EUR"]),
                    (["code": "AA", "name": "Atlantis"], nil),
                    ])
            }
            
            do {
                let graph = try Country
                    .leftJoined(with: Country.profile.order(Column("area")))
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"countries\".*, \"countryProfiles\".* FROM \"countries\" LEFT JOIN \"countryProfiles\" ON (\"countryProfiles\".\"countryCode\" = \"countries\".\"code\") ORDER BY \"countryProfiles\".\"area\"")
                
                assertMatch(graph, [
                    (["code": "AA", "name": "Atlantis"], nil),
                    (["code": "DE", "name": "Germany"], ["countryCode": "DE", "area": 357168, "currency": "EUR"]),
                    (["code": "FR", "name": "France"], ["countryCode": "FR", "area": 643801, "currency": "EUR"]),
                    (["code": "US", "name": "United States"], ["countryCode": "US", "area": 9833520, "currency": "USD"]),
                    ])
            }
        }
    }
}
