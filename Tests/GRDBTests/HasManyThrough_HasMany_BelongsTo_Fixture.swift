import XCTest
#if GRDBCIPHER
    import GRDBCipher
#elseif GRDBCUSTOMSQLITE
    import GRDBCustomSQLite
#else
    import GRDB
#endif

struct HasManyThrough_HasMany_BelongsTo_Fixture {
    
    struct Country : TableMapping, RowConvertible, Persistable {
        static let databaseTableName = "countries"
        let code: String
        let name: String
        
        init(row: Row) {
            code = row.value(named: "code")
            name = row.value(named: "name")
        }
        
        func encode(to container: inout PersistenceContainer) {
            container["code"] = code
            container["name"] = name
        }
        
        static let citizenships = hasMany(Citizenship.self)
        static let citizens = hasMany(Citizenship.person, through: citizenships)
    }
    
    struct Citizenship : TableMapping, RowConvertible, Persistable {
        static let databaseTableName = "citizenships"
        let countryCode: String
        let personId: Int64
        let year: Int
        
        init(row: Row) {
            countryCode = row.value(named: "countryCode")
            personId = row.value(named: "personId")
            year = row.value(named: "year")
        }
        
        func encode(to container: inout PersistenceContainer) {
            container["countryCode"] = countryCode
            container["personId"] = personId
            container["year"] = year
        }
        
        static let person = belongsTo(Person.self)
    }
    
    struct Person : TableMapping, RowConvertible, MutablePersistable {
        static let databaseTableName = "persons"
        var id: Int64?
        let name: String
        
        init(row: Row) {
            id = row.value(named: "id")
            name = row.value(named: "name")
        }
        
        func encode(to container: inout PersistenceContainer) {
            container["id"] = id
            container["name"] = name
        }
        
        mutating func didInsert(with rowID: Int64, for column: String?) {
            id = rowID
        }
    }
    
    var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        
        migrator.registerMigration("fixtures") { db in
            try db.create(table: "countries") { t in
                t.column("code", .text).primaryKey()
                t.column("name", .text)
            }
            let france = Country(row: ["code": "FR", "name": "France"])
            let unitedStates = Country(row: ["code": "US", "name": "United States"])
            let germany = Country(row: ["code": "DE", "name": "Germany"])
            try france.insert(db)
            try unitedStates.insert(db)
            try germany.insert(db)
            
            try db.create(table: "persons") { t in
                t.column("id", .integer).primaryKey()
                t.column("name", .text)
            }
            var arthur = Person(row: ["name": "Arthur"])
            var barbara = Person(row: ["name": "Barbara"])
            var craig = Person(row: ["name": "Craig"])
            try arthur.insert(db)
            try barbara.insert(db)
            try craig.insert(db)
            
            try db.create(table: "citizenships") { t in
                t.column("countryCode", .text).references("countries")
                t.column("personId", .integer).references("persons")
                t.column("year", .integer)
            }
            try Citizenship(row: ["countryCode": france.code, "personId": arthur.id, "year": 1973]).insert(db)
            try Citizenship(row: ["countryCode": france.code, "personId": barbara.id, "year": 1996]).insert(db)
            try Citizenship(row: ["countryCode": unitedStates.code, "personId": barbara.id, "year": 2016]).insert(db)
            try Citizenship(row: ["countryCode": unitedStates.code, "personId": craig.id, "year": 2000]).insert(db)
        }
        
        return migrator
    }
}
