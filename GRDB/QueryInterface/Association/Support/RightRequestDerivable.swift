public protocol RightRequestDerivable : RequestDerivable {
    associatedtype RightRequest: RequestDerivable
    func mapRightRequest(_ transform: (RightRequest) -> (RightRequest)) -> Self
}

extension RightRequestDerivable {
    public func select(_ selection: [SQLSelectable]) -> Self {
        return mapRightRequest { $0.select(selection) }
    }
    
    public func distinct() -> Self {
        return mapRightRequest { $0.distinct() }
    }
    
    public func filter(_ predicate: SQLExpressible) -> Self {
        return mapRightRequest { $0.filter(predicate) }
    }
    
    public func group(_ expressions: [SQLExpressible]) -> Self {
        return mapRightRequest { $0.group(expressions) }
    }
    
    public func having(_ predicate: SQLExpressible) -> Self {
        return mapRightRequest { $0.having(predicate) }
    }
    
    public func order(_ orderings: [SQLOrderingTerm]) -> Self {
        return mapRightRequest { $0.order(orderings) }
    }
    
    public func reversed() -> Self {
        return mapRightRequest { $0.reversed() }
    }
    
    public func limit(_ limit: Int, offset: Int?) -> Self {
        return mapRightRequest { $0.limit(limit, offset: offset) }
    }
}
