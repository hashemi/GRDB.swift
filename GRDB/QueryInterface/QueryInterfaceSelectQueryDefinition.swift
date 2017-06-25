// MARK: - QueryInterfaceSelectQueryDefinition

struct QueryInterfaceSelectQueryDefinition {
    var selection: [SQLSelectable]
    var isDistinct: Bool
    var source: SQLSource?
    var whereExpression: SQLExpression?
    var groupByExpressions: [SQLExpression]
    var orderings: [SQLOrderingTerm]
    var isReversed: Bool
    var havingExpression: SQLExpression?
    var limit: SQLLimit?
    
    init(
        select selection: [SQLSelectable],
        isDistinct: Bool = false,
        from source: SQLSource? = nil,
        filter whereExpression: SQLExpression? = nil,
        groupBy groupByExpressions: [SQLExpression] = [],
        orderBy orderings: [SQLOrderingTerm] = [],
        isReversed: Bool = false,
        having havingExpression: SQLExpression? = nil,
        limit: SQLLimit? = nil)
    {
        self.selection = selection
        self.isDistinct = isDistinct
        self.source = source
        self.whereExpression = whereExpression
        self.groupByExpressions = groupByExpressions
        self.orderings = orderings
        self.isReversed = isReversed
        self.havingExpression = havingExpression
        self.limit = limit
    }
    
    func sql(_ arguments: inout StatementArguments?) -> String {
        var sql = "SELECT"
        
        if isDistinct {
            sql += " DISTINCT"
        }
        
        assert(!selection.isEmpty)
        sql += " " + selection.map { $0.resultColumnSQL(&arguments) }.joined(separator: ", ")
        
        if let source = source {
            sql += " FROM " + source.sourceSQL(&arguments)
        }
        
        if let whereExpression = whereExpression {
            sql += " WHERE " + whereExpression.expressionSQL(&arguments)
        }
        
        if !groupByExpressions.isEmpty {
            sql += " GROUP BY " + groupByExpressions.map { $0.expressionSQL(&arguments) }.joined(separator: ", ")
        }
        
        if let havingExpression = havingExpression {
            sql += " HAVING " + havingExpression.expressionSQL(&arguments)
        }
        
        let orderings = self.eventuallyReversedOrderings
        if !orderings.isEmpty {
            sql += " ORDER BY " + orderings.map { $0.orderingTermSQL(&arguments) }.joined(separator: ", ")
        }
        
        if let limit = limit {
            sql += " LIMIT " + limit.sql
        }
        
        return sql
    }
    
    func makeDeleteStatement(_ db: Database) throws -> UpdateStatement {
        guard groupByExpressions.isEmpty else {
            // Programmer error
            fatalError("Can't delete query with GROUP BY expression")
        }
        
        guard havingExpression == nil else {
            // Programmer error
            fatalError("Can't delete query with GROUP BY expression")
        }
        
        guard limit == nil else {
            // Programmer error
            fatalError("Can't delete query with limit")
        }
        
        var sql = "DELETE"
        var arguments: StatementArguments? = StatementArguments()
        
        if let source = source {
            sql += " FROM " + source.sourceSQL(&arguments)
        }
        
        if let whereExpression = whereExpression {
            sql += " WHERE " + whereExpression.expressionSQL(&arguments)
        }
        
        let statement = try db.makeUpdateStatement(sql)
        statement.arguments = arguments!
        return statement
    }
    
    func numberOfColumns(_ db: Database) throws -> Int {
        return try selection.reduce(0) { try $0 + $1.numberOfColumns(db) }
    }
    
    var eventuallyReversedOrderings: [SQLOrderingTerm] {
        if isReversed {
            if orderings.isEmpty {
                // https://www.sqlite.org/lang_createtable.html#rowid
                //
                // > The rowid value can be accessed using one of the special
                // > case-independent names "rowid", "oid", or "_rowid_" in
                // > place of a column name. If a table contains a user defined
                // > column named "rowid", "oid" or "_rowid_", then that name
                // > always refers the explicitly declared column and cannot be
                // > used to retrieve the integer rowid value.
                //
                // Here we assume that rowid is not a custom column.
                // TODO: support for user-defined rowid column.
                // TODO: support for WITHOUT ROWID tables.
                return [Column.rowID.desc]
            } else {
                return orderings.map { $0.reversed }
            }
        } else {
            return orderings
        }
    }
    
    /// Remove ordering
    var unordered: QueryInterfaceSelectQueryDefinition {
        var query = self
        query.isReversed = false
        query.orderings = []
        return query
    }
    
    func qualified(by qualifier: inout SQLSourceQualifier) -> QueryInterfaceSelectQueryDefinition {
        let qualifiedSource = source.map { $0.qualified(by: &qualifier) }
        let selection = self.selection
        let qualifiedSelection = selection.map { $0.qualified(by: qualifier) }
        let qualifiedFilter = whereExpression.map { $0.qualified(by: qualifier) }
        let qualifiedGroupByExpressions = groupByExpressions.map { $0.qualified(by: qualifier) }
        let qualifiedOrderings = eventuallyReversedOrderings.map { $0.qualified(by: qualifier) } // "ORDER BY rowid DESC" has been qualified
        let qualifiedReversed = false // because qualifiedOrderings has been built on eventuallyReversedOrderings
        let qualifiedHavingExpression = havingExpression?.qualified(by: qualifier)
        
        return QueryInterfaceSelectQueryDefinition(
            select: qualifiedSelection,
            isDistinct: isDistinct,
            from: qualifiedSource,
            filter: qualifiedFilter,
            groupBy: qualifiedGroupByExpressions,
            orderBy: qualifiedOrderings,
            isReversed: qualifiedReversed,
            having: qualifiedHavingExpression,
            limit: limit)
    }
}

extension QueryInterfaceSelectQueryDefinition : Request {
    func prepare(_ db: Database) throws -> (SelectStatement, RowAdapter?) {
        var arguments: StatementArguments? = StatementArguments()
        let sql = self.sql(&arguments)
        let statement = try db.makeSelectStatement(sql)
        try statement.setArgumentsWithValidation(arguments!)
        return (statement, nil)
    }
    
    func fetchCount(_ db: Database) throws -> Int {
        return try Int.fetchOne(db, countQuery)!
    }
    
    private var countQuery: QueryInterfaceSelectQueryDefinition {
        guard groupByExpressions.isEmpty && limit == nil else {
            // SELECT ... GROUP BY ...
            // SELECT ... LIMIT ...
            return trivialCountQuery
        }
        
        guard let source = source, case .table = source else {
            // SELECT ... FROM (something which is not a table)
            return trivialCountQuery
        }
        
        assert(!selection.isEmpty)
        if selection.count == 1 {
            guard let count = selection[0].count(distinct: isDistinct) else {
                return trivialCountQuery
            }
            var countQuery = unordered
            countQuery.isDistinct = false
            countQuery.selection = [count.sqlSelectable]
            return countQuery
        } else {
            // SELECT [DISTINCT] expr1, expr2, ... FROM tableName ...
            
            guard !isDistinct else {
                return trivialCountQuery
            }
            
            // SELECT expr1, expr2, ... FROM tableName ...
            // ->
            // SELECT COUNT(*) FROM tableName ...
            var countQuery = unordered
            countQuery.selection = [SQLExpressionCount(SQLStar())]
            return countQuery
        }
    }
    
    // SELECT COUNT(*) FROM (self)
    private var trivialCountQuery: QueryInterfaceSelectQueryDefinition {
        return QueryInterfaceSelectQueryDefinition(
            select: [SQLExpressionCount(SQLStar())],
            from: .query(query: unordered, qualifier: nil))
    }
}

enum SQLJoinOperator : String {
    case join = "JOIN"
    case leftJoin = "LEFT JOIN"
}

indirect enum SQLSource {
    case table(name: String, qualifier: SQLSourceQualifier?)
    case query(query: QueryInterfaceSelectQueryDefinition, qualifier: SQLSourceQualifier?)
    case joined(JoinDefinition)
    
    struct JoinDefinition {
        let joinOp: SQLJoinOperator
        let leftSource: SQLSource
        let rightSource: SQLSource
        let onExpression: SQLExpression?
        let mapping: [(left: String, right: String)]
        
        func qualified(by qualifier: inout SQLSourceQualifier) -> JoinDefinition {
            return JoinDefinition(
                joinOp: joinOp,
                leftSource: leftSource.qualified(by: &qualifier),
                rightSource: rightSource,
                onExpression: onExpression,
                mapping: mapping)
        }
        
        func sourceSQL(_ arguments: inout StatementArguments?) -> String {
            // left JOIN right ON ...
            var sql = ""
            sql += leftSource.sourceSQL(&arguments)
            sql += " \(joinOp.rawValue) "
            sql += rightSource.sourceSQL(&arguments)
            
            // We're generating sql: sources must have been qualified by now
            let leftQualifier = leftSource.rightQualifier!
            let rightQualifier = rightSource.leftQualifier!
            
            var onClauses = mapping
                .map { arrow -> SQLExpression in
                    // right.leftId == left.id
                    let leftColumn = Column(arrow.left).qualified(by: leftQualifier)
                    let rightColumn = Column(arrow.right).qualified(by: rightQualifier)
                    return (rightColumn == leftColumn) }
            
            if let onExpression = onExpression {
                // right.name = 'foo'
                onClauses.append(onExpression)
            }
            
            if !onClauses.isEmpty {
                let onClause = onClauses.suffix(from: 1).reduce(onClauses.first!, &&)
                sql += " ON " + onClause.expressionSQL(&arguments)
            }
            
            return sql
        }
    }
    
//    var qualifier: SQLSourceQualifier? {
//        switch self {
//        case .table(_, let qualifier): return qualifier
//        case .query(_, let qualifier): return qualifier
//        case .joined(let joinDef): return joinDef.leftSource.qualifier
//        }
//    }
    
    var leftQualifier: SQLSourceQualifier? {
        switch self {
        case .table(_, let qualifier): return qualifier
        case .query(_, let qualifier): return qualifier
        case .joined(let joinDef): return joinDef.leftSource.leftQualifier
        }
    }
    
    var rightQualifier: SQLSourceQualifier? {
        switch self {
        case .table(_, let qualifier): return qualifier
        case .query(_, let qualifier): return qualifier
        case .joined(let joinDef): return joinDef.rightSource.rightQualifier
        }
    }
    
    /// An alias or an actual table name
    var qualifiedName: String? {
        switch self {
        case .table(let tableName, let qualifier):
            return qualifier?.qualifiedName ?? tableName
        case .query(_, let qualifier):
            return qualifier?.qualifiedName
        case .joined(let joinDefinition):
            return joinDefinition.leftSource.qualifiedName
        }
    }
    
    /// An actual table name, not an alias
    var tableName: String? {
        switch self {
        case .table(let tableName, _):
            return tableName
        case .query(let query, _):
            return query.source?.tableName
        case .joined(let joinDefinition):
            return joinDefinition.leftSource.tableName
        }
    }

    func sourceSQL(_ arguments: inout StatementArguments?) -> String {
        switch self {
        case .table(let table, let qualifier):
            if let alias = qualifier?.alias {
                return table.quotedDatabaseIdentifier + " AS " + alias.quotedDatabaseIdentifier
            } else {
                return table.quotedDatabaseIdentifier
            }
        case .query(let query, let qualifier):
            if let alias = qualifier?.alias {
                return "(" + query.sql(&arguments) + ") AS " + alias.quotedDatabaseIdentifier
            } else {
                return "(" + query.sql(&arguments) + ")"
            }
        case .joined(let joinDef):
            return joinDef.sourceSQL(&arguments)
        }
    }
    
    func qualified(by qualifier: inout SQLSourceQualifier) -> SQLSource {
        switch self {
        case .table(let tableName, let oldQualifier):
            if let oldQualifier = oldQualifier {
                qualifier = oldQualifier
                return self
            } else {
                qualifier.tableName = tableName
                return .table(
                    name: tableName,
                    qualifier: qualifier)
            }
        case .query(let query, let oldQualifier):
            if let oldQualifier = oldQualifier {
                qualifier = oldQualifier
                return self
            } else {
                return .query(query: query, qualifier: qualifier)
            }
        case .joined(let joinDef):
            return .joined(joinDef.qualified(by: &qualifier))
        }
    }
}

public class SQLSourceQualifier {
    var tableName: String?
    var alias: String?
    
    init() {
        self.tableName = nil
        self.alias = nil
    }
    
    var qualifiedName: String? {
        return alias ?? tableName
    }
}

struct SQLLimit {
    let limit: Int
    let offset: Int?
    
    var sql: String {
        if let offset = offset {
            return "\(limit) OFFSET \(offset)"
        } else {
            return "\(limit)"
        }
    }
}

extension SQLCount {
    var sqlSelectable: SQLSelectable {
        switch self {
        case .star:
            return SQLExpressionCount(SQLStar())
        case .distinct(let expression):
            return SQLExpressionCountDistinct(expression)
        }
    }
}
