import XCTest
#if GRDBCIPHER
    import GRDBCipher
#elseif GRDBCUSTOMSQLITE
    import GRDBCustomSQLite
#else
    import GRDB
#endif

//struct HasManyThroughAssociationFixture {
//    
//    struct Country : TableMapping, RowConvertible, MutablePersistable {
//        static let databaseTableName = "countries"
//        let code: String
//        let name: String
//        
//        init(row: Row) {
//            code = row.value(named: "code")
//            name = row.value(named: "name")
//        }
//        
//        func encode(to container: inout PersistenceContainer) {
//            container["code"] = code
//            container["name"] = name
//        }
//        
//        static let citizenships = hasOne(CountryProfile.self)
//    }
//    
//    struct Citizenship : TableMapping, RowConvertible, MutablePersistable {
//        static let databaseTableName = "citizenships"
//        let countryCode: String
//        
//        init(row: Row) {
//            countryCode = row.value(named: "countryCode")
//            area = row.value(named: "area")
//            currency = row.value(named: "currency")
//        }
//        
//        func encode(to container: inout PersistenceContainer) {
//            container["countryCode"] = countryCode
//            container["area"] = area
//            container["currency"] = currency
//        }
//    }
//    
//    var migrator: DatabaseMigrator {
//        var migrator = DatabaseMigrator()
//        
//        migrator.registerMigration("fixtures") { db in
//            try db.create(table: "authors") { t in
//                t.column("id", .integer).primaryKey()
//                t.column("name", .text).notNull()
//                t.column("birthYear", .integer).notNull()
//            }
//            try db.execute("INSERT INTO authors (name, birthYear) VALUES (?, ?)", arguments: ["Gwendal Roué", 1973])
//            try db.execute("INSERT INTO authors (name, birthYear) VALUES (?, ?)", arguments: ["J. M. Coetzee", 1940])
//            let coetzeeId = db.lastInsertedRowID
//            try db.execute("INSERT INTO authors (name, birthYear) VALUES (?, ?)", arguments: ["Herman Melville", 1819])
//            let melvilleId = db.lastInsertedRowID
//            try db.execute("INSERT INTO authors (name, birthYear) VALUES (?, ?)", arguments: ["Kim Stanley Robinson", 1952])
//            let robinsonId = db.lastInsertedRowID
//            
//            try db.create(table: "books") { t in
//                t.column("id", .integer).primaryKey()
//                t.column("authorId", .integer).references("authors")
//                t.column("title", .text).notNull()
//                t.column("year", .integer).notNull()
//            }
//            
//            try db.execute("INSERT INTO books (authorId, title, year) VALUES (?, ?, ?)", arguments: [coetzeeId, "Foe", 1986])
//            try db.execute("INSERT INTO books (authorId, title, year) VALUES (?, ?, ?)", arguments: [coetzeeId, "Three Stories", 2014])
//            try db.execute("INSERT INTO books (authorId, title, year) VALUES (?, ?, ?)", arguments: [melvilleId, "Moby-Dick", 1851])
//            try db.execute("INSERT INTO books (authorId, title, year) VALUES (?, ?, ?)", arguments: [robinsonId, "New York 2140", 2017])
//            try db.execute("INSERT INTO books (authorId, title, year) VALUES (?, ?, ?)", arguments: [robinsonId, "2312", 2012])
//            try db.execute("INSERT INTO books (authorId, title, year) VALUES (?, ?, ?)", arguments: [robinsonId, "Blue Mars", 1996])
//            try db.execute("INSERT INTO books (authorId, title, year) VALUES (?, ?, ?)", arguments: [robinsonId, "Green Mars", 1994])
//            try db.execute("INSERT INTO books (authorId, title, year) VALUES (?, ?, ?)", arguments: [robinsonId, "Red Mars", 1993])
//            try db.execute("INSERT INTO books (authorId, title, year) VALUES (?, ?, ?)", arguments: [nil, "Unattributed", 2017])
//            
//            try db.create(table: "countries") { t in
//                t.column("code", .text).primaryKey()
//                t.column("name", .text)
//            }
//            try db.execute("INSERT INTO countries (code, name) VALUES (?, ?)", arguments: ["FR", "France"])
//            try db.execute("INSERT INTO countries (code, name) VALUES (?, ?)", arguments: ["US", "United States"])
//            try db.execute("INSERT INTO countries (code, name) VALUES (?, ?)", arguments: ["DE", "Germany"])
//            try db.execute("INSERT INTO countries (code, name) VALUES (?, ?)", arguments: ["AA", "Atlantis"])
//            
//            try db.create(table: "countryProfiles") { t in
//                t.column("countryCode", .text).primaryKey().references("countries")
//                t.column("area", .double)
//                t.column("currency", .text)
//            }
//            try db.execute("INSERT INTO countryProfiles (countryCode, area, currency) VALUES (?, ?, ?)", arguments: ["FR", 643801, "EUR"])
//            try db.execute("INSERT INTO countryProfiles (countryCode, area, currency) VALUES (?, ?, ?)", arguments: ["US", 9833520, "USD"])
//            try db.execute("INSERT INTO countryProfiles (countryCode, area, currency) VALUES (?, ?, ?)", arguments: ["DE", 357168, "EUR"])
//        }
//        
//        return migrator
//    }
//}
