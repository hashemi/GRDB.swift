import XCTest
#if GRDBCIPHER
    import GRDBCipher
#elseif GRDBCUSTOMSQLITE
    import GRDBCustomSQLite
#else
    import GRDB
#endif

class HasManyThroughAssociationHasManyBelongsToAnnotatedTests: GRDBTestCase {
    // TODO
}