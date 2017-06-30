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

class HasOneJoinedRequestTests: GRDBTestCase {
    
    func testSimplestRequest() throws {
        let dbQueue = try makeDatabaseQueue()
        try AssociationFixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            let graph = try Country
                .joined(with: Country.profile)
                .fetchAll(db)
            
            XCTAssertEqual(lastSQLQuery, "SELECT \"countries\".* FROM \"countries\" JOIN \"countryProfiles\" ON (\"countryProfiles\".\"countryCode\" = \"countries\".\"code\")")
            
            assertMatch(graph, [
                ["code": "FR", "name": "France"],
                ["code": "US", "name": "United States"],
                ["code": "DE", "name": "Germany"],
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
                    .joined(with: Country.profile)
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"countries\".* FROM \"countries\" JOIN \"countryProfiles\" ON (\"countryProfiles\".\"countryCode\" = \"countries\".\"code\") WHERE (\"countries\".\"code\" <> 'FR')")
                
                assertMatch(graph, [
                    ["code": "US", "name": "United States"],
                    ["code": "DE", "name": "Germany"],
                    ])
            }
            
            do {
                // filter after
                let graph = try Country
                    .joined(with: Country.profile)
                    .filter(Column("code") != "FR")
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"countries\".* FROM \"countries\" JOIN \"countryProfiles\" ON (\"countryProfiles\".\"countryCode\" = \"countries\".\"code\") WHERE (\"countries\".\"code\" <> 'FR')")
                
                assertMatch(graph, [
                    ["code": "US", "name": "United States"],
                    ["code": "DE", "name": "Germany"],
                    ])
            }
            
            do {
                // order before
                let graph = try Country
                    .order(Column("code"))
                    .joined(with: Country.profile)
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"countries\".* FROM \"countries\" JOIN \"countryProfiles\" ON (\"countryProfiles\".\"countryCode\" = \"countries\".\"code\") ORDER BY \"countries\".\"code\"")
                
                assertMatch(graph, [
                    ["code": "DE", "name": "Germany"],
                    ["code": "FR", "name": "France"],
                    ["code": "US", "name": "United States"],
                    ])
            }
            
            do {
                // order after
                let graph = try Country
                    .joined(with: Country.profile)
                    .order(Column("code"))
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"countries\".* FROM \"countries\" JOIN \"countryProfiles\" ON (\"countryProfiles\".\"countryCode\" = \"countries\".\"code\") ORDER BY \"countries\".\"code\"")
                
                assertMatch(graph, [
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
                    .joined(with: Country.profile.filter(Column("currency") == "EUR"))
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"countries\".* FROM \"countries\" JOIN \"countryProfiles\" ON ((\"countryProfiles\".\"countryCode\" = \"countries\".\"code\") AND (\"countryProfiles\".\"currency\" = \'EUR\'))")
                
                assertMatch(graph, [
                    ["code": "FR", "name": "France"],
                    ["code": "DE", "name": "Germany"],
                    ])
            }
            
            do {
                let graph = try Country
                    .joined(with: Country.profile.order(Column("area")))
                    .fetchAll(db)
                
                XCTAssertEqual(lastSQLQuery, "SELECT \"countries\".* FROM \"countries\" JOIN \"countryProfiles\" ON (\"countryProfiles\".\"countryCode\" = \"countries\".\"code\")")
                
                assertMatch(graph, [
                    ["code": "FR", "name": "France"],
                    ["code": "US", "name": "United States"],
                    ["code": "DE", "name": "Germany"],
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
                let request = Person.all().joined(with: association)
                try assertSQL(db, request, "SELECT \"persons1\".* FROM \"persons\" \"persons1\" JOIN \"persons\" \"persons2\" ON (\"persons2\".\"parentId\" = \"persons1\".\"id\")")
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
                    .joined(with: Country.profile)
                try assertSQL(db, request, "SELECT \"c\".* FROM \"countries\" \"c\" JOIN \"countryProfiles\" ON (\"countryProfiles\".\"countryCode\" = \"c\".\"code\") WHERE (\"c\".\"code\" <> \'FR\')")
            }
            
            do {
                // alias last
                let request = Country
                    .filter(Column("code") != "FR")
                    .joined(with: Country.profile)
                    .aliased("c")
                try assertSQL(db, request, "SELECT \"c\".* FROM \"countries\" \"c\" JOIN \"countryProfiles\" ON (\"countryProfiles\".\"countryCode\" = \"c\".\"code\") WHERE (\"c\".\"code\" <> \'FR\')")
            }
        }
    }
    
    func testRightAlias() throws {
        let dbQueue = try makeDatabaseQueue()
        try AssociationFixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            do {
                // alias first
                let request = Country.joined(with: Country.profile.aliased("p").filter(Column("currency") == "EUR"))
                try assertSQL(db, request, "SELECT \"countries\".* FROM \"countries\" JOIN \"countryProfiles\" \"p\" ON ((\"p\".\"countryCode\" = \"countries\".\"code\") AND (\"p\".\"currency\" = \'EUR\'))")
            }
            
            do {
                // alias last
                let request = Country.joined(with: Country.profile.order(Column("area")).aliased("p"))
                try assertSQL(db, request, "SELECT \"countries\".* FROM \"countries\" JOIN \"countryProfiles\" \"p\" ON (\"p\".\"countryCode\" = \"countries\".\"code\")")
            }
        }
    }
    
    func testLockedAlias() throws {
        let dbQueue = try makeDatabaseQueue()
        try AssociationFixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            do {
                // alias left
                let request = Country.joined(with: Country.profile).aliased("COUNTRYPROFILES")
                try assertSQL(db, request, "SELECT \"COUNTRYPROFILES\".* FROM \"countries\" \"COUNTRYPROFILES\" JOIN \"countryProfiles\" \"countryProfiles1\" ON (\"countryProfiles1\".\"countryCode\" = \"COUNTRYPROFILES\".\"code\")")
            }
            
            do {
                // alias right
                let request = Country.joined(with: Country.profile.aliased("COUNTRIES"))
                try assertSQL(db, request, "SELECT \"countries1\".* FROM \"countries\" \"countries1\" JOIN \"countryProfiles\" \"COUNTRIES\" ON (\"COUNTRIES\".\"countryCode\" = \"countries1\".\"code\")")
            }
        }
    }
    
    func testConflictingAlias() throws {
        let dbQueue = try makeDatabaseQueue()
        try AssociationFixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            do {
                let request = Country.joined(with: Country.profile.aliased("a")).aliased("A")
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
