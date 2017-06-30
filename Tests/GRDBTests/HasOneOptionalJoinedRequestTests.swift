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

class HasOneOptionalJoinedRequestTests: GRDBTestCase {
    
    func testSimplestRequest() throws {
        let dbQueue = try makeDatabaseQueue()
        try AssociationFixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            let graph = try Country
                .joined(with: Country.optionalProfile)
                .fetchAll(db)
            
            XCTAssertEqual(lastSQLQuery, "SELECT \"countries\".* FROM \"countries\" LEFT JOIN \"countryProfiles\" ON (\"countryProfiles\".\"countryCode\" = \"countries\".\"code\")")
            
            assertMatch(graph, [
                ["code": "FR", "name": "France"],
                ["code": "US", "name": "United States"],
                ["code": "DE", "name": "Germany"],
                ["code": "AA", "name": "Atlantis"],
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
                    .joined(with: Country.optionalProfile)
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"countries\".* FROM \"countries\" LEFT JOIN \"countryProfiles\" ON (\"countryProfiles\".\"countryCode\" = \"countries\".\"code\") WHERE (\"countries\".\"code\" <> 'FR')")
                
                assertMatch(graph, [
                    ["code": "US", "name": "United States"],
                    ["code": "DE", "name": "Germany"],
                    ["code": "AA", "name": "Atlantis"],
                    ])
            }
            
            do {
                // filter after
                let graph = try Country
                    .joined(with: Country.optionalProfile)
                    .filter(Column("code") != "FR")
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"countries\".* FROM \"countries\" LEFT JOIN \"countryProfiles\" ON (\"countryProfiles\".\"countryCode\" = \"countries\".\"code\") WHERE (\"countries\".\"code\" <> 'FR')")
                
                assertMatch(graph, [
                    ["code": "US", "name": "United States"],
                    ["code": "DE", "name": "Germany"],
                    ["code": "AA", "name": "Atlantis"],
                    ])
            }
            
            do {
                // order before
                let graph = try Country
                    .order(Column("code"))
                    .joined(with: Country.optionalProfile)
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"countries\".* FROM \"countries\" LEFT JOIN \"countryProfiles\" ON (\"countryProfiles\".\"countryCode\" = \"countries\".\"code\") ORDER BY \"countries\".\"code\"")
                
                assertMatch(graph, [
                    ["code": "AA", "name": "Atlantis"],
                    ["code": "DE", "name": "Germany"],
                    ["code": "FR", "name": "France"],
                    ["code": "US", "name": "United States"],
                    ])
            }
            
            do {
                // order after
                let graph = try Country
                    .joined(with: Country.optionalProfile)
                    .order(Column("code"))
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"countries\".* FROM \"countries\" LEFT JOIN \"countryProfiles\" ON (\"countryProfiles\".\"countryCode\" = \"countries\".\"code\") ORDER BY \"countries\".\"code\"")
                
                assertMatch(graph, [
                    ["code": "AA", "name": "Atlantis"],
                    ["code": "DE", "name": "Germany"],
                    ["code": "FR", "name": "France"],
                    ["code": "US", "name": "United States"],
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
                    .joined(with: Country.optionalProfile.filter(Column("currency") == "EUR"))
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"countries\".* FROM \"countries\" LEFT JOIN \"countryProfiles\" ON ((\"countryProfiles\".\"countryCode\" = \"countries\".\"code\") AND (\"countryProfiles\".\"currency\" = \'EUR\'))")
                
                assertMatch(graph, [
                    ["code": "FR", "name": "France"],
                    ["code": "US", "name": "United States"],
                    ["code": "DE", "name": "Germany"],
                    ["code": "AA", "name": "Atlantis"],
                    ])
            }
            
            do {
                let graph = try Country
                    .joined(with: Country.optionalProfile.order(Column("area")))
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"countries\".* FROM \"countries\" LEFT JOIN \"countryProfiles\" ON (\"countryProfiles\".\"countryCode\" = \"countries\".\"code\")")
                
                assertMatch(graph, [
                    ["code": "FR", "name": "France"],
                    ["code": "US", "name": "United States"],
                    ["code": "DE", "name": "Germany"],
                    ["code": "AA", "name": "Atlantis"],
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
                let association = Person.hasOne(optional: Person.self)
                let request = Person.all().joined(with: association)
                try assertSQL(db, request, "SELECT \"persons1\".* FROM \"persons\" \"persons1\" LEFT JOIN \"persons\" \"persons2\" ON (\"persons2\".\"parentId\" = \"persons1\".\"id\")")
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
                    .joined(with: Country.optionalProfile)
                try assertSQL(db, request, "SELECT \"c\".* FROM \"countries\" \"c\" LEFT JOIN \"countryProfiles\" ON (\"countryProfiles\".\"countryCode\" = \"c\".\"code\") WHERE (\"c\".\"code\" <> \'FR\')")
            }
            
            do {
                // alias last
                let request = Country
                    .filter(Column("code") != "FR")
                    .joined(with: Country.optionalProfile)
                    .aliased("c")
                try assertSQL(db, request, "SELECT \"c\".* FROM \"countries\" \"c\" LEFT JOIN \"countryProfiles\" ON (\"countryProfiles\".\"countryCode\" = \"c\".\"code\") WHERE (\"c\".\"code\" <> \'FR\')")
            }
        }
    }
    
    func testRightAlias() throws {
        let dbQueue = try makeDatabaseQueue()
        try AssociationFixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            do {
                // alias first
                let request = Country.joined(with: Country.optionalProfile.aliased("p").filter(Column("currency") == "EUR"))
                try assertSQL(db, request, "SELECT \"countries\".* FROM \"countries\" LEFT JOIN \"countryProfiles\" \"p\" ON ((\"p\".\"countryCode\" = \"countries\".\"code\") AND (\"p\".\"currency\" = \'EUR\'))")
            }
            
            do {
                // alias last
                let request = Country.joined(with: Country.optionalProfile.order(Column("area")).aliased("p"))
                try assertSQL(db, request, "SELECT \"countries\".* FROM \"countries\" LEFT JOIN \"countryProfiles\" \"p\" ON (\"p\".\"countryCode\" = \"countries\".\"code\")")
            }
        }
    }
    
    func testLockedAlias() throws {
        let dbQueue = try makeDatabaseQueue()
        try AssociationFixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            do {
                // alias left
                let request = Country.joined(with: Country.optionalProfile).aliased("COUNTRYPROFILES")
                try assertSQL(db, request, "SELECT \"COUNTRYPROFILES\".* FROM \"countries\" \"COUNTRYPROFILES\" LEFT JOIN \"countryProfiles\" \"countryProfiles1\" ON (\"countryProfiles1\".\"countryCode\" = \"COUNTRYPROFILES\".\"code\")")
            }
            
            do {
                // alias right
                let request = Country.joined(with: Country.optionalProfile.aliased("COUNTRIES"))
                try assertSQL(db, request, "SELECT \"countries1\".* FROM \"countries\" \"countries1\" LEFT JOIN \"countryProfiles\" \"COUNTRIES\" ON (\"COUNTRIES\".\"countryCode\" = \"countries1\".\"code\")")
            }
        }
    }
    
    func testConflictingAlias() throws {
        let dbQueue = try makeDatabaseQueue()
        try AssociationFixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            do {
                let request = Country.joined(with: Country.optionalProfile.aliased("a")).aliased("A")
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
