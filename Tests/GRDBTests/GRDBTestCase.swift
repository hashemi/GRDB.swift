import XCTest
#if SWIFT_PACKAGE
    import CSQLite
#endif
#if GRDBCIPHER
    @testable import GRDBCipher // @testable so that we have access to SQLiteConnectionWillClose
#elseif GRDBCUSTOMSQLITE
    @testable import GRDBCustomSQLite // @testable so that we have access to SQLiteConnectionWillClose
#else
    @testable import GRDB       // @testable so that we have access to SQLiteConnectionWillClose
#endif

class GRDBTestCase: XCTestCase {
    // The default configuration for tests
    var dbConfiguration: Configuration!
    
    // Builds a database queue based on dbConfiguration
    func makeDatabaseQueue(filename: String = "db.sqlite") throws -> DatabaseQueue {
        try FileManager.default.createDirectory(atPath: dbDirectoryPath, withIntermediateDirectories: true, attributes: nil)
        let dbPath = (dbDirectoryPath as NSString).appendingPathComponent(filename)
        let dbQueue = try DatabaseQueue(path: dbPath, configuration: dbConfiguration)
        try setup(dbQueue)
        return dbQueue
    }
    
    // Builds a database pool based on dbConfiguration
    func makeDatabasePool(filename: String = "db.sqlite") throws -> DatabasePool {
        try FileManager.default.createDirectory(atPath: dbDirectoryPath, withIntermediateDirectories: true, attributes: nil)
        let dbPath = (dbDirectoryPath as NSString).appendingPathComponent(filename)
        let dbPool = try DatabasePool(path: dbPath, configuration: dbConfiguration)
        try setup(dbPool)
        return dbPool
    }
    
    // Subclasses can override
    // Default implementation is empty.
    func setup(_ dbWriter: DatabaseWriter) throws {
    }
    
    // The default path for database pool directory
    private var dbDirectoryPath: String!
    
    // Populated by default configuration
    var sqlQueries: [String]!   // TODO: protect against concurrent accesses
    
    // Populated by default configuration
    var lastSQLQuery: String! {
        return sqlQueries.last!
    }
    
    override func setUp() {
        super.setUp()
        
        let dbPoolDirectoryName = "GRDBTestCase-\(ProcessInfo.processInfo.globallyUniqueString)"
        dbDirectoryPath = (NSTemporaryDirectory() as NSString).appendingPathComponent(dbPoolDirectoryName)
        do { try FileManager.default.removeItem(atPath: dbDirectoryPath) } catch { }
        
        dbConfiguration = Configuration()
        
        // Test that database are deallocated in a clean state
        dbConfiguration.SQLiteConnectionWillClose = { sqliteConnection in
            // https://www.sqlite.org/capi3ref.html#sqlite3_close:
            // > If sqlite3_close_v2() is called on a database connection that still
            // > has outstanding prepared statements, BLOB handles, and/or
            // > sqlite3_backup objects then it returns SQLITE_OK and the
            // > deallocation of resources is deferred until all prepared
            // > statements, BLOB handles, and sqlite3_backup objects are also
            // > destroyed.
            //
            // Let's assert that there is no longer any busy update statements.
            //
            // SQLite would allow that. But not GRDB, since all updates happen
            // in closures that retain database connections, preventing
            // Database.deinit to fire.
            //
            // What we gain from this test is a guarantee that database
            // deallocation implies that there is no pending lock in the
            // database.
            //
            // See:
            // - sqlite3_next_stmt https://www.sqlite.org/capi3ref.html#sqlite3_next_stmt
            // - sqlite3_stmt_busy https://www.sqlite.org/capi3ref.html#sqlite3_stmt_busy
            // - sqlite3_stmt_readonly https://www.sqlite.org/capi3ref.html#sqlite3_stmt_readonly
            var stmt: SQLiteStatement? = sqlite3_next_stmt(sqliteConnection, nil)
            while stmt != nil {
                XCTAssertTrue(sqlite3_stmt_readonly(stmt) != 0 || sqlite3_stmt_busy(stmt) == 0)
                stmt = sqlite3_next_stmt(sqliteConnection, stmt)
            }
        }
        
        dbConfiguration.trace = { [unowned self] sql in
            self.sqlQueries.append(sql)
        }
        
        #if GRDBCIPHER_USE_ENCRYPTION
            // We are testing encrypted databases.
            dbConfiguration.passphrase = "secret"
        #endif
        
        sqlQueries = []
    }
    
    override func tearDown() {
        super.tearDown()
        do { try FileManager.default.removeItem(atPath: dbDirectoryPath) } catch { }
    }
    
    func assertNoError(file: StaticString = #file, line: UInt = #line, _ test: () throws -> Void) {
        do {
            try test()
        } catch {
            XCTFail("unexpected error: \(error)", file: file, line: line)
        }
    }
    
    func assertDidExecute(sql: String) {
        XCTAssertTrue(sqlQueries.contains(sql), "Did not execute \(sql)")
    }
    
    // TODO: rename assertMatch
    func assert(_ record: MutablePersistable, isEncodedIn row: Row, file: StaticString = #file, line: UInt = #line) {
        let recordContent = AnySequence({ PersistenceContainer(record).makeIterator() })
        for (column, value) in recordContent {
            if let dbValue: DatabaseValue = row.value(named: column) {
                XCTAssertEqual(dbValue, value?.databaseValue ?? .null, file: file, line: line)
            } else {
                XCTFail("Missing column \(column) in fetched row", file: file, line: line)
            }
        }
    }
    
    func assertMatch<T>(_ record: T?, _ expectedRow: Row?, file: StaticString = #file, line: UInt = #line) where T: MutablePersistable {
        switch (record, expectedRow) {
        case (let record?, let row?):
            assert(record, isEncodedIn: row, file: file, line: line)
        case (nil, nil):
            break
        default:
            XCTFail("no match", file: file, line: line)
        }
    }
    
    func assertSQL(_ reader: DatabaseReader, _ request: Request, _ sql: String, file: StaticString = #file, line: UInt = #line) throws {
        try reader.unsafeRead { db in
            try assertSQL(db, request, sql, file: file, line: line)
        }
    }
    
    func assertSQL(_ db: Database, _ request: Request, _ sql: String, file: StaticString = #file, line: UInt = #line) throws {
        _ = try Row.fetchOne(db, request)
        XCTAssertEqual(lastSQLQuery, sql, file: file, line: line)
    }
    
    // TODO: refactor around assertSQL
    func sql(_ databaseReader: DatabaseReader, _ request: Request) -> String {
        return try! databaseReader.unsafeRead { db in
            _ = try Row.fetchOne(db, request)
            return lastSQLQuery
        }
    }
}

extension Array {
    func decompose() -> (Iterator.Element, [Iterator.Element])? {
        guard let x = first else { return nil }
        return (x, Array(suffix(from: index(after: startIndex))))
    }
    
    // https://gist.github.com/proxpero/9fd3c4726d19242365d6
    var permutations: [[Iterator.Element]] {
        func between(_ x: Iterator.Element, _ ys: [Iterator.Element]) -> [[Iterator.Element]] {
            guard let (head, tail) = ys.decompose() else { return [[x]] }
            return [[x] + ys] + between(x, tail).map { [head] + $0 }
        }
        guard let (head, tail) = decompose() else { return [[]] }
        return tail.permutations.flatMap { between(head, $0) }
    }
}

extension Array where Iterator.Element: DatabaseValueConvertible {
    // [1, 2, 3].sqlPermutations => ["1, 2, 3", "1, 3, 2", "2, 1, 3", "2, 3, 1", "3, 1, 2", "3, 2, 1"]
    var sqlPermutations: [String] {
        return map { $0.databaseValue.sql }
            .permutations
            .map { $0.joined(separator: ", ") }
    }
}
