import XCTest
#if GRDBCIPHER
    @testable import GRDBCipher
#elseif GRDBCUSTOMSQLITE
    @testable import GRDBCustomSQLite
#else
    @testable import GRDB
#endif

private typealias Country = AssociationFixture.Country
private typealias CountryProfile = AssociationFixture.CountryProfile

class HasOneAssociationJoinedTests: GRDBTestCase {
    
    func testSimplestRequest() throws {
        let dbQueue = try makeDatabaseQueue()
        try AssociationFixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            let graph = try Country
                .joined(with: Country.profile)
                .fetchAll(db)
            
            XCTAssertEqual(lastSQLQuery, "SELECT \"left\".*, \"right\".* FROM \"countries\" AS \"left\" JOIN \"countryProfiles\" AS \"right\" ON (\"right\".\"countryCode\" = \"left\".\"code\")")
            
            assertMatch(graph, [
                (["code": "FR", "name": "France"], ["countryCode": "FR", "area": 643801, "currency": "EUR"]),
                (["code": "US", "name": "United States"], ["countryCode": "US", "area": 9833520, "currency": "USD"]),
                (["code": "DE", "name": "Germany"], ["countryCode": "DE", "area": 357168, "currency": "EUR"]),
                ])
        }
    }
    
    func testLeftRequestDerivation() throws {
        let dbQueue = try makeDatabaseQueue()
        try AssociationFixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            do {
                // filter before joined
                let graph = try Country
                    .filter(Column("code") != "FR")
                    .joined(with: Country.profile)
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"left\".*, \"right\".* FROM \"countries\" AS \"left\" JOIN \"countryProfiles\" AS \"right\" ON (\"right\".\"countryCode\" = \"left\".\"code\") WHERE (\"left\".\"code\" <> 'FR')")
                
                assertMatch(graph, [
                    (["code": "US", "name": "United States"], ["countryCode": "US", "area": 9833520, "currency": "USD"]),
                    (["code": "DE", "name": "Germany"], ["countryCode": "DE", "area": 357168, "currency": "EUR"]),
                    ])
            }
            
            do {
                // filter after joined
                let graph = try Country
                    .joined(with: Country.profile)
                    .filter(Column("code") != "FR")
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"left\".*, \"right\".* FROM \"countries\" AS \"left\" JOIN \"countryProfiles\" AS \"right\" ON (\"right\".\"countryCode\" = \"left\".\"code\") WHERE (\"left\".\"code\" <> 'FR')")
                
                assertMatch(graph, [
                    (["code": "US", "name": "United States"], ["countryCode": "US", "area": 9833520, "currency": "USD"]),
                    (["code": "DE", "name": "Germany"], ["countryCode": "DE", "area": 357168, "currency": "EUR"]),
                    ])
            }
            
            do {
                // order before joined
                let graph = try Country
                    .order(Column("code"))
                    .joined(with: Country.profile)
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"left\".*, \"right\".* FROM \"countries\" AS \"left\" JOIN \"countryProfiles\" AS \"right\" ON (\"right\".\"countryCode\" = \"left\".\"code\") ORDER BY \"left\".\"code\"")
                
                assertMatch(graph, [
                    (["code": "DE", "name": "Germany"], ["countryCode": "DE", "area": 357168, "currency": "EUR"]),
                    (["code": "FR", "name": "France"], ["countryCode": "FR", "area": 643801, "currency": "EUR"]),
                    (["code": "US", "name": "United States"], ["countryCode": "US", "area": 9833520, "currency": "USD"]),
                    ])
            }
            
            do {
                // order after joined
                let graph = try Country
                    .joined(with: Country.profile)
                    .order(Column("code"))
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"left\".*, \"right\".* FROM \"countries\" AS \"left\" JOIN \"countryProfiles\" AS \"right\" ON (\"right\".\"countryCode\" = \"left\".\"code\") ORDER BY \"left\".\"code\"")
                
                assertMatch(graph, [
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
                    .joined(with: Country.profile.filter(Column("currency") == "EUR"))
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"left\".*, \"right\".* FROM \"countries\" AS \"left\" JOIN \"countryProfiles\" AS \"right\" ON ((\"right\".\"countryCode\" = \"left\".\"code\") AND (\"right\".\"currency\" = \'EUR\'))")
                
                assertMatch(graph, [
                    (["code": "FR", "name": "France"], ["countryCode": "FR", "area": 643801, "currency": "EUR"]),
                    (["code": "DE", "name": "Germany"], ["countryCode": "DE", "area": 357168, "currency": "EUR"]),
                    ])
            }
            
            do {
                let graph = try Country
                    .joined(with: Country.profile.order(Column("area")))
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"left\".*, \"right\".* FROM \"countries\" AS \"left\" JOIN \"countryProfiles\" AS \"right\" ON (\"right\".\"countryCode\" = \"left\".\"code\") ORDER BY \"right\".\"area\"")
                
                assertMatch(graph, [
                    (["code": "DE", "name": "Germany"], ["countryCode": "DE", "area": 357168, "currency": "EUR"]),
                    (["code": "FR", "name": "France"], ["countryCode": "FR", "area": 643801, "currency": "EUR"]),
                    (["code": "US", "name": "United States"], ["countryCode": "US", "area": 9833520, "currency": "USD"]),
                    ])
            }
        }
    }
}
