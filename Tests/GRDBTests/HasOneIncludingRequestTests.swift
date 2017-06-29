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

class HasOneIncludingRequestTests: GRDBTestCase {
    
    func testSimplestRequest() throws {
        let dbQueue = try makeDatabaseQueue()
        try AssociationFixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            let graph = try Country
                .including(Country.profile)
                .fetchAll(db)
            
            XCTAssertEqual(lastSQLQuery, "SELECT \"countries\".*, \"countryProfiles\".* FROM \"countries\" JOIN \"countryProfiles\" ON (\"countryProfiles\".\"countryCode\" = \"countries\".\"code\")")
            
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
                // filter before
                let graph = try Country
                    .filter(Column("code") != "FR")
                    .including(Country.profile)
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"countries\".*, \"countryProfiles\".* FROM \"countries\" JOIN \"countryProfiles\" ON (\"countryProfiles\".\"countryCode\" = \"countries\".\"code\") WHERE (\"countries\".\"code\" <> 'FR')")
                
                assertMatch(graph, [
                    (["code": "US", "name": "United States"], ["countryCode": "US", "area": 9833520, "currency": "USD"]),
                    (["code": "DE", "name": "Germany"], ["countryCode": "DE", "area": 357168, "currency": "EUR"]),
                    ])
            }
            
            do {
                // filter after
                let graph = try Country
                    .including(Country.profile)
                    .filter(Column("code") != "FR")
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"countries\".*, \"countryProfiles\".* FROM \"countries\" JOIN \"countryProfiles\" ON (\"countryProfiles\".\"countryCode\" = \"countries\".\"code\") WHERE (\"countries\".\"code\" <> 'FR')")
                
                assertMatch(graph, [
                    (["code": "US", "name": "United States"], ["countryCode": "US", "area": 9833520, "currency": "USD"]),
                    (["code": "DE", "name": "Germany"], ["countryCode": "DE", "area": 357168, "currency": "EUR"]),
                    ])
            }
            
            do {
                // order before
                let graph = try Country
                    .order(Column("code"))
                    .including(Country.profile)
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"countries\".*, \"countryProfiles\".* FROM \"countries\" JOIN \"countryProfiles\" ON (\"countryProfiles\".\"countryCode\" = \"countries\".\"code\") ORDER BY \"countries\".\"code\"")
                
                assertMatch(graph, [
                    (["code": "DE", "name": "Germany"], ["countryCode": "DE", "area": 357168, "currency": "EUR"]),
                    (["code": "FR", "name": "France"], ["countryCode": "FR", "area": 643801, "currency": "EUR"]),
                    (["code": "US", "name": "United States"], ["countryCode": "US", "area": 9833520, "currency": "USD"]),
                    ])
            }
            
            do {
                // order after
                let graph = try Country
                    .including(Country.profile)
                    .order(Column("code"))
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"countries\".*, \"countryProfiles\".* FROM \"countries\" JOIN \"countryProfiles\" ON (\"countryProfiles\".\"countryCode\" = \"countries\".\"code\") ORDER BY \"countries\".\"code\"")
                
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
                    .including(Country.profile.filter(Column("currency") == "EUR"))
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"countries\".*, \"countryProfiles\".* FROM \"countries\" JOIN \"countryProfiles\" ON ((\"countryProfiles\".\"countryCode\" = \"countries\".\"code\") AND (\"countryProfiles\".\"currency\" = \'EUR\'))")
                
                assertMatch(graph, [
                    (["code": "FR", "name": "France"], ["countryCode": "FR", "area": 643801, "currency": "EUR"]),
                    (["code": "DE", "name": "Germany"], ["countryCode": "DE", "area": 357168, "currency": "EUR"]),
                    ])
            }
            
            do {
                let graph = try Country
                    .including(Country.profile.order(Column("area")))
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"countries\".*, \"countryProfiles\".* FROM \"countries\" JOIN \"countryProfiles\" ON (\"countryProfiles\".\"countryCode\" = \"countries\".\"code\") ORDER BY \"countryProfiles\".\"area\"")
                
                assertMatch(graph, [
                    (["code": "DE", "name": "Germany"], ["countryCode": "DE", "area": 357168, "currency": "EUR"]),
                    (["code": "FR", "name": "France"], ["countryCode": "FR", "area": 643801, "currency": "EUR"]),
                    (["code": "US", "name": "United States"], ["countryCode": "US", "area": 9833520, "currency": "USD"]),
                    ])
            }
        }
    }
    
    func testRecursion() throws {
        struct Person : TableMapping {
            static let databaseTableName = "persons"
        }
        
        let dbQueue = try makeDatabaseQueue()
        try dbQueue.inDatabase { db in
            try db.create(table: "persons") { t in
                t.column("id", .integer).primaryKey()
                t.column("parentId", .integer).references("persons")
            }
        }
        
        try dbQueue.inDatabase { db in
            do {
                let association = Person.hasOne(Person.self)
                let request = Person.all().including(association)
                try assertSQL(db, request, "SELECT \"persons1\".*, \"persons2\".* FROM \"persons\" \"persons1\" JOIN \"persons\" \"persons2\" ON (\"persons2\".\"parentId\" = \"persons1\".\"id\")")
            }
        }
    }
    
    func testLeftAlias() throws {
        let dbQueue = try makeDatabaseQueue()
        try AssociationFixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            do {
                // alias first
                let request = Country.all()
                    .aliased("c")
                    .filter(Column("code") != "FR")
                    .including(Country.profile)
                try assertSQL(db, request, "SELECT \"c\".*, \"countryProfiles\".* FROM \"countries\" \"c\" JOIN \"countryProfiles\" ON (\"countryProfiles\".\"countryCode\" = \"c\".\"code\") WHERE (\"c\".\"code\" <> \'FR\')")
            }
            
            do {
                // alias last
                let request = Country
                    .filter(Column("code") != "FR")
                    .including(Country.profile)
                    .aliased("c")
                try assertSQL(db, request, "SELECT \"c\".*, \"countryProfiles\".* FROM \"countries\" \"c\" JOIN \"countryProfiles\" ON (\"countryProfiles\".\"countryCode\" = \"c\".\"code\") WHERE (\"c\".\"code\" <> \'FR\')")
            }
        }
    }
    
    func testRightAlias() throws {
        let dbQueue = try makeDatabaseQueue()
        try AssociationFixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            do {
                // alias first
                let request = Country.including(Country.profile.aliased("p").filter(Column("currency") == "EUR"))
                try assertSQL(db, request, "SELECT \"countries\".*, \"p\".* FROM \"countries\" JOIN \"countryProfiles\" \"p\" ON ((\"p\".\"countryCode\" = \"countries\".\"code\") AND (\"p\".\"currency\" = \'EUR\'))")
            }
            
            do {
                // alias last
                let request = Country.including(Country.profile.order(Column("area")).aliased("p"))
                try assertSQL(db, request, "SELECT \"countries\".*, \"p\".* FROM \"countries\" JOIN \"countryProfiles\" \"p\" ON (\"p\".\"countryCode\" = \"countries\".\"code\") ORDER BY \"p\".\"area\"")
            }
        }
    }
    
    func testLockedAlias() throws {
        let dbQueue = try makeDatabaseQueue()
        try AssociationFixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            do {
                // alias left
                let request = Country.including(Country.profile).aliased("COUNTRYPROFILES")
                try assertSQL(db, request, "SELECT \"COUNTRYPROFILES\".*, \"countryProfiles1\".* FROM \"countries\" \"COUNTRYPROFILES\" JOIN \"countryProfiles\" \"countryProfiles1\" ON (\"countryProfiles1\".\"countryCode\" = \"COUNTRYPROFILES\".\"code\")")
            }
            
            do {
                // alias right
                let request = Country.including(Country.profile.aliased("COUNTRIES"))
                try assertSQL(db, request, "SELECT \"countries1\".*, \"COUNTRIES\".* FROM \"countries\" \"countries1\" JOIN \"countryProfiles\" \"COUNTRIES\" ON (\"COUNTRIES\".\"countryCode\" = \"countries1\".\"code\")")
            }
        }
    }
    
    func testConflictingAlias() throws {
        let dbQueue = try makeDatabaseQueue()
        try AssociationFixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            do {
                let request = Country.including(Country.profile.aliased("a")).aliased("A")
                _ = try request.fetchAll(db)
                XCTFail("Expected error")
            } catch let error as DatabaseError {
                XCTAssertEqual(error.resultCode, .SQLITE_ERROR)
                XCTAssertEqual(error.message!, "ambiguous alias: A")
                XCTAssertNil(error.sql)
                XCTAssertEqual(error.description, "SQLite error 1: ambiguous alias: A")
            }
        }
    }
}
