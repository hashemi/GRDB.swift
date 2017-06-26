// Remove RightRequestDerivable conformance once https://github.com/apple/swift-evolution/blob/master/proposals/0143-conditional-conformances.md is implemented
public struct HasManyThroughRightRequest<MiddleAssociation: Association, RightAssociation: Association> where MiddleAssociation.LeftAssociated: MutablePersistable, MiddleAssociation.RightAssociated == RightAssociation.LeftAssociated, RightAssociation: RightRequestDerivable, RightAssociation.RightRowDecoder == RightAssociation.RightAssociated {
    let record: MiddleAssociation.LeftAssociated
    let association: HasManyThroughAssociation<MiddleAssociation, RightAssociation>
}

extension HasManyThroughRightRequest : TypedRequest {
    public typealias RowDecoder = RightAssociation.RightAssociated
    
    public func prepare(_ db: Database) throws -> (SelectStatement, RowAdapter?) {
        var middleQualifier = SQLSourceQualifier()
        var rightQualifier = SQLSourceQualifier()
        
        // SELECT * FROM middle ... -> SELECT middle.* FROM middle WHERE middle.leftId = left.id ...
        let middleMapping = try association.middleAssociation.mapping(db)
        let container = PersistenceContainer(record)
        let rowValue = RowValue(middleMapping.map { container[caseInsensitive: $0.left]?.databaseValue ?? .null })
        let middleQuery = association.middleAssociation.rightRequest
            .filter(middleMapping.map { Column($0.right) } == rowValue)
            .query.qualified(by: &middleQualifier)
        
        // SELECT * FROM right ... -> SELECT right.* FROM right ...
        let rightQuery = association.rightAssociation.rightRequest.query.qualified(by: &rightQualifier)
        
        // ... FROM right JOIN middle
        guard let middleSource = middleQuery.source else { fatalError("Support for sourceless joins is not implemented") }
        guard let rightSource = rightQuery.source else { fatalError("Support for sourceless joins is not implemented") }
        let joinedSource = try SQLSource.joined(SQLSource.JoinDefinition(
            joinOp: .join,
            leftSource: rightSource,
            rightSource: middleSource,
            onExpression: middleQuery.whereExpression,
            mapping: association.rightAssociation.mapping(db).map { (left: $0.right, right: $0.left ) }))
        
        // ORDER BY right.***, middle.***
        let joinedOrderings = rightQuery.eventuallyReversedOrderings + middleQuery.eventuallyReversedOrderings
        
        return try QueryInterfaceSelectQueryDefinition(
            select: rightQuery.selection,
            isDistinct: rightQuery.isDistinct,
            from: joinedSource,
            filter: rightQuery.whereExpression,
            groupBy: rightQuery.groupByExpressions,
            orderBy: joinedOrderings,
            isReversed: false,
            having: rightQuery.havingExpression,
            limit: rightQuery.limit)
            .prepare(db)
    }
}

extension HasManyThroughRightRequest : RightRequestDerivable {
    public typealias RightRowDecoder = RightAssociation.RightAssociated
    public func mapRightRequest(_ transform: (QueryInterfaceRequest<RightAssociation.RightAssociated>) -> QueryInterfaceRequest<RightAssociation.RightAssociated>) -> HasManyThroughRightRequest<MiddleAssociation, RightAssociation> {
        return HasManyThroughRightRequest(record: record, association: association.mapRightRequest(transform))
    }
}

extension HasManyThroughAssociation where MiddleAssociation.LeftAssociated: MutablePersistable {
    func makeRequest(from record: MiddleAssociation.LeftAssociated) -> HasManyThroughRightRequest<MiddleAssociation, RightAssociation> {
        return HasManyThroughRightRequest(record: record, association: self)
    }
}

extension MutablePersistable {
    public func makeRequest<MiddleAssociation, RightAssociation>(_ association: HasManyThroughAssociation<MiddleAssociation, RightAssociation>) -> HasManyThroughRightRequest<MiddleAssociation, RightAssociation> where MiddleAssociation.LeftAssociated == Self {
        return association.makeRequest(from: self)
    }
    
    public func fetchCursor<MiddleAssociation, RightAssociation>(_ db: Database, _ association: HasManyThroughAssociation<MiddleAssociation, RightAssociation>) throws -> DatabaseCursor<RightAssociation.RightAssociated> where MiddleAssociation.LeftAssociated == Self, RightAssociation.RightAssociated: RowConvertible {
        return try association.makeRequest(from: self).fetchCursor(db)
    }
    
    public func fetchAll<MiddleAssociation, RightAssociation>(_ db: Database, _ association: HasManyThroughAssociation<MiddleAssociation, RightAssociation>) throws -> [RightAssociation.RightAssociated] where MiddleAssociation.LeftAssociated == Self, RightAssociation.RightAssociated: RowConvertible {
        return try association.makeRequest(from: self).fetchAll(db)
    }
    
    public func fetchOne<MiddleAssociation, RightAssociation>(_ db: Database, _ association: HasManyThroughAssociation<MiddleAssociation, RightAssociation>) throws -> RightAssociation.RightAssociated? where MiddleAssociation.LeftAssociated == Self, RightAssociation.RightAssociated: RowConvertible {
        return try association.makeRequest(from: self).fetchOne(db)
    }
}
