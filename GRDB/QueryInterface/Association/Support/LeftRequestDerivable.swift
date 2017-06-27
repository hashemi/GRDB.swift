protocol LeftRequestDerivable : RequestDerivable {
    associatedtype LeftRequest: RequestDerivable
    func mapLeftRequest(_ transform: (LeftRequest) -> (LeftRequest)) -> Self
}

extension LeftRequestDerivable {
    public func select(_ selection: [SQLSelectable]) -> Self {
        return mapLeftRequest { $0.select(selection) }
    }
    
    public func distinct() -> Self {
        return mapLeftRequest { $0.distinct() }
    }
    
    public func filter(_ predicate: SQLExpressible) -> Self {
        return mapLeftRequest { $0.filter(predicate) }
    }
    
    public func group(_ expressions: [SQLExpressible]) -> Self {
        return mapLeftRequest { $0.group(expressions) }
    }
    
    public func having(_ predicate: SQLExpressible) -> Self {
        return mapLeftRequest { $0.having(predicate) }
    }
    
    public func order(_ orderings: [SQLOrderingTerm]) -> Self {
        return mapLeftRequest { $0.order(orderings) }
    }
    
    public func reversed() -> Self {
        return mapLeftRequest { $0.reversed() }
    }
    
    public func limit(_ limit: Int, offset: Int?) -> Self {
        return mapLeftRequest { $0.limit(limit, offset: offset) }
    }
}
