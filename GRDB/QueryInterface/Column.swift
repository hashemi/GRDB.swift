/// A column in the database
///
/// See https://github.com/groue/GRDB.swift#the-query-interface
public struct Column {
    /// The hidden rowID column
    public static let rowID = Column("rowid")
    
    /// The name of the column
    public let name: String
    
    /// The eventual qualifier
    let qualifier: SQLSourceQualifier?
    
    /// Creates a column given its name.
    public init(_ name: String) {
        self.name = name
        self.qualifier = nil
    }
    
    init(_ name: String, qualifier: SQLSourceQualifier) {
        self.name = name
        self.qualifier = qualifier
    }
}

extension Column : SQLExpression {
    
    /// [**Experimental**](http://github.com/groue/GRDB.swift#what-are-experimental-features)
    public func expressionSQL(_ arguments: inout StatementArguments?) -> String {
        if let qualifiedName = qualifier?.qualifiedName {
            return "\(qualifiedName.quotedDatabaseIdentifier).\(name.quotedDatabaseIdentifier)"
        } else {
            return name.quotedDatabaseIdentifier
        }
    }
    
    /// [**Experimental**](http://github.com/groue/GRDB.swift#what-are-experimental-features)
    public func qualified(by qualifier: SQLSourceQualifier) -> Column {
        if self.qualifier == nil {
            return Column(name, qualifier: qualifier)
        } else {
            return self
        }
    }
}
