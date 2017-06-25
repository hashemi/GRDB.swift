import XCTest
#if GRDBCIPHER
    import GRDBCipher
#elseif GRDBCUSTOMSQLITE
    import GRDBCustomSQLite
#else
    import GRDB
#endif

class BelongsToAssociationTests: GRDBTestCase {
    
    func testSingleColumnNoForeignKeyNoPrimaryKey() throws {
        struct Child : TableMapping, MutablePersistable {
            static let databaseTableName = "children"
            func encode(to container: inout PersistenceContainer) {
                container["parentId"] = 1
            }
        }
        
        struct Parent : TableMapping {
            static let databaseTableName = "parents"
        }
        
        let dbQueue = try makeDatabaseQueue()
        try dbQueue.inDatabase { db in
            try db.create(table: "parents") { t in
                t.column("id", .integer)
            }
            try db.create(table: "children") { t in
                t.column("parentId", .integer)
            }
        }
        
        try dbQueue.inDatabase { db in
            do {
                let association = Child.belongsTo(Parent.self, from: "parentId")
                try assertSQL(db, Child.all().joined(with: association), "SELECT \"left\".*, \"right\".* FROM \"children\" AS \"left\" JOIN \"parents\" AS \"right\" ON (\"right\".\"rowid\" = \"left\".\"parentId\")")
                try assertSQL(db, Child.all().leftJoined(with: association), "SELECT \"left\".*, \"right\".* FROM \"children\" AS \"left\" LEFT JOIN \"parents\" AS \"right\" ON (\"right\".\"rowid\" = \"left\".\"parentId\")")
                try assertSQL(db, Child().makeRequest(association), "SELECT * FROM \"parents\" WHERE (\"rowid\" = 1)")
            }
            do {
                let association = Child.belongsTo(Parent.self, from: ["parentId"], to: ["id"])
                try assertSQL(db, Child.all().joined(with: association), "SELECT \"left\".*, \"right\".* FROM \"children\" AS \"left\" JOIN \"parents\" AS \"right\" ON (\"right\".\"id\" = \"left\".\"parentId\")")
                try assertSQL(db, Child.all().leftJoined(with: association), "SELECT \"left\".*, \"right\".* FROM \"children\" AS \"left\" LEFT JOIN \"parents\" AS \"right\" ON (\"right\".\"id\" = \"left\".\"parentId\")")
                try assertSQL(db, Child().makeRequest(association), "SELECT * FROM \"parents\" WHERE (\"id\" = 1)")
            }
        }
    }
    
    func testSingleColumnNoForeignKey() throws {
        struct Child : TableMapping, MutablePersistable {
            static let databaseTableName = "children"
            func encode(to container: inout PersistenceContainer) {
                container["parentId"] = 1
            }
        }
        
        struct Parent : TableMapping {
            static let databaseTableName = "parents"
        }
        
        let dbQueue = try makeDatabaseQueue()
        try dbQueue.inDatabase { db in
            try db.create(table: "parents") { t in
                t.column("id", .integer).primaryKey()
            }
            try db.create(table: "children") { t in
                t.column("parentId", .integer)
            }
        }
        
        try dbQueue.inDatabase { db in
            do {
                let association = Child.belongsTo(Parent.self, from: "parentId")
                try assertSQL(db, Child.all().joined(with: association), "SELECT \"left\".*, \"right\".* FROM \"children\" AS \"left\" JOIN \"parents\" AS \"right\" ON (\"right\".\"id\" = \"left\".\"parentId\")")
                try assertSQL(db, Child.all().leftJoined(with: association), "SELECT \"left\".*, \"right\".* FROM \"children\" AS \"left\" LEFT JOIN \"parents\" AS \"right\" ON (\"right\".\"id\" = \"left\".\"parentId\")")
                try assertSQL(db, Child().makeRequest(association), "SELECT * FROM \"parents\" WHERE (\"id\" = 1)")
            }
            do {
                let association = Child.belongsTo(Parent.self, from: ["parentId"], to: ["id"])
                try assertSQL(db, Child.all().joined(with: association), "SELECT \"left\".*, \"right\".* FROM \"children\" AS \"left\" JOIN \"parents\" AS \"right\" ON (\"right\".\"id\" = \"left\".\"parentId\")")
                try assertSQL(db, Child.all().leftJoined(with: association), "SELECT \"left\".*, \"right\".* FROM \"children\" AS \"left\" LEFT JOIN \"parents\" AS \"right\" ON (\"right\".\"id\" = \"left\".\"parentId\")")
                try assertSQL(db, Child().makeRequest(association), "SELECT * FROM \"parents\" WHERE (\"id\" = 1)")
            }
        }
    }
    
    func testSingleColumnSingleForeignKey() throws {
        struct Child : TableMapping, MutablePersistable {
            static let databaseTableName = "children"
            func encode(to container: inout PersistenceContainer) {
                container["parentId"] = 1
            }
        }
        
        struct Parent : TableMapping {
            static let databaseTableName = "parents"
        }
        
        let dbQueue = try makeDatabaseQueue()
        try dbQueue.inDatabase { db in
            try db.create(table: "parents") { t in
                t.column("id", .integer).primaryKey()
            }
            try db.create(table: "children") { t in
                t.column("parentId", .integer).references("parents")
            }
        }
        
        try dbQueue.inDatabase { db in
            do {
                let association = Child.belongsTo(Parent.self)
                try assertSQL(db, Child.all().joined(with: association), "SELECT \"left\".*, \"right\".* FROM \"children\" AS \"left\" JOIN \"parents\" AS \"right\" ON (\"right\".\"id\" = \"left\".\"parentId\")")
                try assertSQL(db, Child.all().leftJoined(with: association), "SELECT \"left\".*, \"right\".* FROM \"children\" AS \"left\" LEFT JOIN \"parents\" AS \"right\" ON (\"right\".\"id\" = \"left\".\"parentId\")")
                try assertSQL(db, Child().makeRequest(association), "SELECT * FROM \"parents\" WHERE (\"id\" = 1)")
            }
            do {
                let association = Child.belongsTo(Parent.self, from: "parentId")
                try assertSQL(db, Child.all().joined(with: association), "SELECT \"left\".*, \"right\".* FROM \"children\" AS \"left\" JOIN \"parents\" AS \"right\" ON (\"right\".\"id\" = \"left\".\"parentId\")")
                try assertSQL(db, Child.all().leftJoined(with: association), "SELECT \"left\".*, \"right\".* FROM \"children\" AS \"left\" LEFT JOIN \"parents\" AS \"right\" ON (\"right\".\"id\" = \"left\".\"parentId\")")
                try assertSQL(db, Child().makeRequest(association), "SELECT * FROM \"parents\" WHERE (\"id\" = 1)")
            }
            do {
                let association = Child.belongsTo(Parent.self, from: ["parentId"], to: ["id"])
                try assertSQL(db, Child.all().joined(with: association), "SELECT \"left\".*, \"right\".* FROM \"children\" AS \"left\" JOIN \"parents\" AS \"right\" ON (\"right\".\"id\" = \"left\".\"parentId\")")
                try assertSQL(db, Child.all().leftJoined(with: association), "SELECT \"left\".*, \"right\".* FROM \"children\" AS \"left\" LEFT JOIN \"parents\" AS \"right\" ON (\"right\".\"id\" = \"left\".\"parentId\")")
                try assertSQL(db, Child().makeRequest(association), "SELECT * FROM \"parents\" WHERE (\"id\" = 1)")
            }
        }
    }
    
    func testSingleColumnSeveralForeignKeys() throws {
        struct Child : TableMapping, MutablePersistable {
            static let databaseTableName = "children"
            func encode(to container: inout PersistenceContainer) {
                container["parent1Id"] = 1
                container["parent2Id"] = 2
            }
        }
        
        struct Parent : TableMapping {
            static let databaseTableName = "parents"
        }
        
        let dbQueue = try makeDatabaseQueue()
        try dbQueue.inDatabase { db in
            try db.create(table: "parents") { t in
                t.column("id", .integer).primaryKey()
            }
            try db.create(table: "children") { t in
                t.column("parent1Id", .integer).references("parents")
                t.column("parent2Id", .integer).references("parents")
            }
        }
        
        try dbQueue.inDatabase { db in
            do {
                let association = Child.belongsTo(Parent.self, from: "parent1Id")
                try assertSQL(db, Child.all().joined(with: association), "SELECT \"left\".*, \"right\".* FROM \"children\" AS \"left\" JOIN \"parents\" AS \"right\" ON (\"right\".\"id\" = \"left\".\"parent1Id\")")
                try assertSQL(db, Child.all().leftJoined(with: association), "SELECT \"left\".*, \"right\".* FROM \"children\" AS \"left\" LEFT JOIN \"parents\" AS \"right\" ON (\"right\".\"id\" = \"left\".\"parent1Id\")")
                try assertSQL(db, Child().makeRequest(association), "SELECT * FROM \"parents\" WHERE (\"id\" = 1)")
            }
            do {
                let association = Child.belongsTo(Parent.self, from: ["parent1Id"], to: ["id"])
                try assertSQL(db, Child.all().joined(with: association), "SELECT \"left\".*, \"right\".* FROM \"children\" AS \"left\" JOIN \"parents\" AS \"right\" ON (\"right\".\"id\" = \"left\".\"parent1Id\")")
                try assertSQL(db, Child.all().leftJoined(with: association), "SELECT \"left\".*, \"right\".* FROM \"children\" AS \"left\" LEFT JOIN \"parents\" AS \"right\" ON (\"right\".\"id\" = \"left\".\"parent1Id\")")
                try assertSQL(db, Child().makeRequest(association), "SELECT * FROM \"parents\" WHERE (\"id\" = 1)")
            }
            do {
                let association = Child.belongsTo(Parent.self, from: "parent2Id")
                try assertSQL(db, Child.all().joined(with: association), "SELECT \"left\".*, \"right\".* FROM \"children\" AS \"left\" JOIN \"parents\" AS \"right\" ON (\"right\".\"id\" = \"left\".\"parent2Id\")")
                try assertSQL(db, Child.all().leftJoined(with: association), "SELECT \"left\".*, \"right\".* FROM \"children\" AS \"left\" LEFT JOIN \"parents\" AS \"right\" ON (\"right\".\"id\" = \"left\".\"parent2Id\")")
                try assertSQL(db, Child().makeRequest(association), "SELECT * FROM \"parents\" WHERE (\"id\" = 2)")
            }
            do {
                let association = Child.belongsTo(Parent.self, from: ["parent2Id"], to: ["id"])
                try assertSQL(db, Child.all().joined(with: association), "SELECT \"left\".*, \"right\".* FROM \"children\" AS \"left\" JOIN \"parents\" AS \"right\" ON (\"right\".\"id\" = \"left\".\"parent2Id\")")
                try assertSQL(db, Child.all().leftJoined(with: association), "SELECT \"left\".*, \"right\".* FROM \"children\" AS \"left\" LEFT JOIN \"parents\" AS \"right\" ON (\"right\".\"id\" = \"left\".\"parent2Id\")")
                try assertSQL(db, Child().makeRequest(association), "SELECT * FROM \"parents\" WHERE (\"id\" = 2)")
            }
        }
    }
    
    func testCompoundColumnNoForeignKeyNoPrimaryKey() throws {
        struct Child : TableMapping, MutablePersistable {
            static let databaseTableName = "children"
            func encode(to container: inout PersistenceContainer) {
                container["parentA"] = 1
                container["parentB"] = 2
            }
        }
        
        struct Parent : TableMapping {
            static let databaseTableName = "parents"
        }
        
        let dbQueue = try makeDatabaseQueue()
        try dbQueue.inDatabase { db in
            try db.create(table: "parents") { t in
                t.column("a", .integer)
                t.column("b", .integer)
            }
            try db.create(table: "children") { t in
                t.column("parentA", .integer)
                t.column("parentB", .integer)
            }
        }
        
        try dbQueue.inDatabase { db in
            do {
                let association = Child.belongsTo(Parent.self, from: ["parentA", "parentB"], to: ["a", "b"])
                try assertSQL(db, Child.all().joined(with: association), "SELECT \"left\".*, \"right\".* FROM \"children\" AS \"left\" JOIN \"parents\" AS \"right\" ON ((\"right\".\"a\" = \"left\".\"parentA\") AND (\"right\".\"b\" = \"left\".\"parentB\"))")
                try assertSQL(db, Child.all().leftJoined(with: association), "SELECT \"left\".*, \"right\".* FROM \"children\" AS \"left\" LEFT JOIN \"parents\" AS \"right\" ON ((\"right\".\"a\" = \"left\".\"parentA\") AND (\"right\".\"b\" = \"left\".\"parentB\"))")
                try assertSQL(db, Child().makeRequest(association), "SELECT * FROM \"parents\" WHERE ((\"a\" = 1) AND (\"b\" = 2))")
            }
        }
    }
    
    func testCompoundColumnNoForeignKey() throws {
        struct Child : TableMapping, MutablePersistable {
            static let databaseTableName = "children"
            func encode(to container: inout PersistenceContainer) {
                container["parentA"] = 1
                container["parentB"] = 2
            }
        }
        
        struct Parent : TableMapping {
            static let databaseTableName = "parents"
        }
        
        let dbQueue = try makeDatabaseQueue()
        try dbQueue.inDatabase { db in
            try db.create(table: "parents") { t in
                t.column("a", .integer)
                t.column("b", .integer)
                t.primaryKey(["a", "b"])
            }
            try db.create(table: "children") { t in
                t.column("parentA", .integer)
                t.column("parentB", .integer)
            }
        }
        
        try dbQueue.inDatabase { db in
            do {
                let association = Child.belongsTo(Parent.self, from: "parentA", "parentB")
                try assertSQL(db, Child.all().joined(with: association), "SELECT \"left\".*, \"right\".* FROM \"children\" AS \"left\" JOIN \"parents\" AS \"right\" ON ((\"right\".\"a\" = \"left\".\"parentA\") AND (\"right\".\"b\" = \"left\".\"parentB\"))")
                try assertSQL(db, Child.all().leftJoined(with: association), "SELECT \"left\".*, \"right\".* FROM \"children\" AS \"left\" LEFT JOIN \"parents\" AS \"right\" ON ((\"right\".\"a\" = \"left\".\"parentA\") AND (\"right\".\"b\" = \"left\".\"parentB\"))")
                try assertSQL(db, Child().makeRequest(association), "SELECT * FROM \"parents\" WHERE ((\"a\" = 1) AND (\"b\" = 2))")
            }
            do {
                let association = Child.belongsTo(Parent.self, from: ["parentA", "parentB"], to: ["a", "b"])
                try assertSQL(db, Child.all().joined(with: association), "SELECT \"left\".*, \"right\".* FROM \"children\" AS \"left\" JOIN \"parents\" AS \"right\" ON ((\"right\".\"a\" = \"left\".\"parentA\") AND (\"right\".\"b\" = \"left\".\"parentB\"))")
                try assertSQL(db, Child.all().leftJoined(with: association), "SELECT \"left\".*, \"right\".* FROM \"children\" AS \"left\" LEFT JOIN \"parents\" AS \"right\" ON ((\"right\".\"a\" = \"left\".\"parentA\") AND (\"right\".\"b\" = \"left\".\"parentB\"))")
                try assertSQL(db, Child().makeRequest(association), "SELECT * FROM \"parents\" WHERE ((\"a\" = 1) AND (\"b\" = 2))")
            }
        }
    }
    
    func testCompoundColumnSingleForeignKey() throws {
        struct Child : TableMapping, MutablePersistable {
            static let databaseTableName = "children"
            func encode(to container: inout PersistenceContainer) {
                container["parentA"] = 1
                container["parentB"] = 2
            }
        }
        
        struct Parent : TableMapping {
            static let databaseTableName = "parents"
        }
        
        let dbQueue = try makeDatabaseQueue()
        try dbQueue.inDatabase { db in
            try db.create(table: "parents") { t in
                t.column("a", .integer)
                t.column("b", .integer)
                t.primaryKey(["a", "b"])
            }
            try db.create(table: "children") { t in
                t.column("parentA", .integer)
                t.column("parentB", .integer)
                t.foreignKey(["parentA", "parentB"], references: "parents")
            }
        }
        
        try dbQueue.inDatabase { db in
            do {
                let association = Child.belongsTo(Parent.self)
                try assertSQL(db, Child.all().joined(with: association), "SELECT \"left\".*, \"right\".* FROM \"children\" AS \"left\" JOIN \"parents\" AS \"right\" ON ((\"right\".\"a\" = \"left\".\"parentA\") AND (\"right\".\"b\" = \"left\".\"parentB\"))")
                try assertSQL(db, Child.all().leftJoined(with: association), "SELECT \"left\".*, \"right\".* FROM \"children\" AS \"left\" LEFT JOIN \"parents\" AS \"right\" ON ((\"right\".\"a\" = \"left\".\"parentA\") AND (\"right\".\"b\" = \"left\".\"parentB\"))")
                try assertSQL(db, Child().makeRequest(association), "SELECT * FROM \"parents\" WHERE ((\"a\" = 1) AND (\"b\" = 2))")
            }
            do {
                let association = Child.belongsTo(Parent.self, from: "parentA", "parentB")
                try assertSQL(db, Child.all().joined(with: association), "SELECT \"left\".*, \"right\".* FROM \"children\" AS \"left\" JOIN \"parents\" AS \"right\" ON ((\"right\".\"a\" = \"left\".\"parentA\") AND (\"right\".\"b\" = \"left\".\"parentB\"))")
                try assertSQL(db, Child.all().leftJoined(with: association), "SELECT \"left\".*, \"right\".* FROM \"children\" AS \"left\" LEFT JOIN \"parents\" AS \"right\" ON ((\"right\".\"a\" = \"left\".\"parentA\") AND (\"right\".\"b\" = \"left\".\"parentB\"))")
                try assertSQL(db, Child().makeRequest(association), "SELECT * FROM \"parents\" WHERE ((\"a\" = 1) AND (\"b\" = 2))")
            }
            do {
                let association = Child.belongsTo(Parent.self, from: ["parentA", "parentB"], to: ["a", "b"])
                try assertSQL(db, Child.all().joined(with: association), "SELECT \"left\".*, \"right\".* FROM \"children\" AS \"left\" JOIN \"parents\" AS \"right\" ON ((\"right\".\"a\" = \"left\".\"parentA\") AND (\"right\".\"b\" = \"left\".\"parentB\"))")
                try assertSQL(db, Child.all().leftJoined(with: association), "SELECT \"left\".*, \"right\".* FROM \"children\" AS \"left\" LEFT JOIN \"parents\" AS \"right\" ON ((\"right\".\"a\" = \"left\".\"parentA\") AND (\"right\".\"b\" = \"left\".\"parentB\"))")
                try assertSQL(db, Child().makeRequest(association), "SELECT * FROM \"parents\" WHERE ((\"a\" = 1) AND (\"b\" = 2))")
            }
        }
    }
    
    func testCompoundColumnSeveralForeignKeys() throws {
        struct Child : TableMapping, MutablePersistable {
            static let databaseTableName = "children"
            func encode(to container: inout PersistenceContainer) {
                container["parent1A"] = 1
                container["parent1B"] = 2
                container["parent2A"] = 3
                container["parent2B"] = 4
            }
        }
        
        struct Parent : TableMapping {
            static let databaseTableName = "parents"
        }
        
        let dbQueue = try makeDatabaseQueue()
        try dbQueue.inDatabase { db in
            try db.create(table: "parents") { t in
                t.column("a", .integer)
                t.column("b", .integer)
                t.primaryKey(["a", "b"])
            }
            try db.create(table: "children") { t in
                t.column("parent1A", .integer)
                t.column("parent1B", .integer)
                t.column("parent2A", .integer)
                t.column("parent2B", .integer)
                t.foreignKey(["parent1A", "parent1B"], references: "parents")
                t.foreignKey(["parent2A", "parent2B"], references: "parents")
            }
        }
        
        try dbQueue.inDatabase { db in
            do {
                let association = Child.belongsTo(Parent.self, from: "parent1A", "parent1B")
                try assertSQL(db, Child.all().joined(with: association), "SELECT \"left\".*, \"right\".* FROM \"children\" AS \"left\" JOIN \"parents\" AS \"right\" ON ((\"right\".\"a\" = \"left\".\"parent1A\") AND (\"right\".\"b\" = \"left\".\"parent1B\"))")
                try assertSQL(db, Child.all().leftJoined(with: association), "SELECT \"left\".*, \"right\".* FROM \"children\" AS \"left\" LEFT JOIN \"parents\" AS \"right\" ON ((\"right\".\"a\" = \"left\".\"parent1A\") AND (\"right\".\"b\" = \"left\".\"parent1B\"))")
                try assertSQL(db, Child().makeRequest(association), "SELECT * FROM \"parents\" WHERE ((\"a\" = 1) AND (\"b\" = 2))")
            }
            do {
                let association = Child.belongsTo(Parent.self, from: ["parent1A", "parent1B"], to: ["a", "b"])
                try assertSQL(db, Child.all().joined(with: association), "SELECT \"left\".*, \"right\".* FROM \"children\" AS \"left\" JOIN \"parents\" AS \"right\" ON ((\"right\".\"a\" = \"left\".\"parent1A\") AND (\"right\".\"b\" = \"left\".\"parent1B\"))")
                try assertSQL(db, Child.all().leftJoined(with: association), "SELECT \"left\".*, \"right\".* FROM \"children\" AS \"left\" LEFT JOIN \"parents\" AS \"right\" ON ((\"right\".\"a\" = \"left\".\"parent1A\") AND (\"right\".\"b\" = \"left\".\"parent1B\"))")
                try assertSQL(db, Child().makeRequest(association), "SELECT * FROM \"parents\" WHERE ((\"a\" = 1) AND (\"b\" = 2))")
            }
            do {
                let association = Child.belongsTo(Parent.self, from: "parent2A", "parent2B")
                try assertSQL(db, Child.all().joined(with: association), "SELECT \"left\".*, \"right\".* FROM \"children\" AS \"left\" JOIN \"parents\" AS \"right\" ON ((\"right\".\"a\" = \"left\".\"parent2A\") AND (\"right\".\"b\" = \"left\".\"parent2B\"))")
                try assertSQL(db, Child.all().leftJoined(with: association), "SELECT \"left\".*, \"right\".* FROM \"children\" AS \"left\" LEFT JOIN \"parents\" AS \"right\" ON ((\"right\".\"a\" = \"left\".\"parent2A\") AND (\"right\".\"b\" = \"left\".\"parent2B\"))")
                try assertSQL(db, Child().makeRequest(association), "SELECT * FROM \"parents\" WHERE ((\"a\" = 3) AND (\"b\" = 4))")
            }
            do {
                let association = Child.belongsTo(Parent.self, from: ["parent2A", "parent2B"], to: ["a", "b"])
                try assertSQL(db, Child.all().joined(with: association), "SELECT \"left\".*, \"right\".* FROM \"children\" AS \"left\" JOIN \"parents\" AS \"right\" ON ((\"right\".\"a\" = \"left\".\"parent2A\") AND (\"right\".\"b\" = \"left\".\"parent2B\"))")
                try assertSQL(db, Child.all().leftJoined(with: association), "SELECT \"left\".*, \"right\".* FROM \"children\" AS \"left\" LEFT JOIN \"parents\" AS \"right\" ON ((\"right\".\"a\" = \"left\".\"parent2A\") AND (\"right\".\"b\" = \"left\".\"parent2B\"))")
                try assertSQL(db, Child().makeRequest(association), "SELECT * FROM \"parents\" WHERE ((\"a\" = 3) AND (\"b\" = 4))")
            }
        }
    }
}
