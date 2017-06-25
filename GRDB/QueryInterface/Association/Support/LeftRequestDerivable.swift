protocol LeftRequestDerivable {
    associatedtype LeftRowDecoder
    func mapLeftRequest(_ transform: (QueryInterfaceRequest<LeftRowDecoder>) -> (QueryInterfaceRequest<LeftRowDecoder>)) -> Self
}

extension LeftRequestDerivable {
    public func select(_ selection: SQLSelectable...) -> Self {
        return mapLeftRequest { $0.select(selection) }
    }
    
    public func select(_ selection: [SQLSelectable]) -> Self {
        return mapLeftRequest { $0.select(selection) }
    }
    
    public func select(sql: String, arguments: StatementArguments? = nil) -> Self {
        return mapLeftRequest { $0.select(sql: sql, arguments: arguments) }
    }
    
    public func distinct() -> Self {
        return mapLeftRequest { $0.distinct() }
    }
    
    public func filter(_ predicate: SQLExpressible) -> Self {
        return mapLeftRequest { $0.filter(predicate) }
    }
    
    public func filter(sql: String, arguments: StatementArguments? = nil) -> Self {
        return mapLeftRequest { $0.filter(sql: sql, arguments: arguments) }
    }
    
    public func group(_ expressions: SQLExpressible...) -> Self {
        return mapLeftRequest { $0.group(expressions) }
    }
    
    public func group(_ expressions: [SQLExpressible]) -> Self {
        return mapLeftRequest { $0.group(expressions) }
    }
    
    public func group(sql: String, arguments: StatementArguments? = nil) -> Self {
        return mapLeftRequest { $0.group(sql: sql, arguments: arguments) }
    }
    
    public func having(_ predicate: SQLExpressible) -> Self {
        return mapLeftRequest { $0.having(predicate) }
    }
    
    public func having(sql: String, arguments: StatementArguments? = nil) -> Self {
        return mapLeftRequest { $0.having(sql: sql, arguments: arguments) }
    }
    
    public func order(_ orderings: SQLOrderingTerm...) -> Self {
        return mapLeftRequest { $0.order(orderings) }
    }
    
    public func order(_ orderings: [SQLOrderingTerm]) -> Self {
        return mapLeftRequest { $0.order(orderings) }
    }
    
    public func order(sql: String, arguments: StatementArguments? = nil) -> Self {
        return mapLeftRequest { $0.order(sql: sql, arguments: arguments) }
    }
    
    public func reversed() -> Self {
        return mapLeftRequest { $0.reversed() }
    }
    
    public func limit(_ limit: Int, offset: Int? = nil) -> Self {
        return mapLeftRequest { $0.limit(limit, offset: offset) }
    }
}
