public struct HasManyThroughRightRequest<Left: MutablePersistable, Middle: TableMapping, Right: TableMapping> {
    let record: Left
    let association: HasManyThroughAssociation<Left, Middle, Right>
}

extension HasManyThroughRightRequest : TypedRequest {
    public typealias RowDecoder = Right
    
    public func prepare(_ db: Database) throws -> (SelectStatement, RowAdapter?) {
        let middleMapping = try association.middleMapping(db)
        let container = PersistenceContainer(record)
        let rowValue = RowValue(middleMapping.map { container[caseInsensitive: $0.left]?.databaseValue ?? .null })
        
        var middleQualifier = SQLSourceQualifier()
        var rightQualifier = SQLSourceQualifier()
        
        // SELECT * FROM middle ... -> SELECT middle.* FROM middle WHERE middle.leftId = left.id ...
        let middleQuery = association.middleRequest.filter(middleMapping.map { Column($0.right) } == rowValue).query.qualified(by: &middleQualifier)
        
        // SELECT * FROM right ... -> SELECT right.* FROM right ...
        let rightQuery = association.rightRequest.query.qualified(by: &rightQualifier)
        
        // ... FROM right JOIN middle
        guard let middleSource = middleQuery.source else { fatalError("Support for sourceless joins is not implemented") }
        guard let rightSource = rightQuery.source else { fatalError("Support for sourceless joins is not implemented") }
        let joinedSource = try SQLSource.joined(SQLSource.JoinDefinition(
            joinOp: .join,
            leftSource: rightSource,
            rightSource: middleSource,
            onExpression: middleQuery.whereExpression,
            mapping: association.rightMapping(db).map { (left: $0.right, right: $0.left ) }))
        
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
    typealias RightRowDecoder = Right
    func mapRightRequest(_ transform: (QueryInterfaceRequest<Right>) -> QueryInterfaceRequest<Right>) -> HasManyThroughRightRequest<Left, Middle, Right> {
        return HasManyThroughRightRequest(record: record, association: association.mapRightRequest(transform))
    }
}

extension HasManyThroughAssociation where Left: MutablePersistable {
    func makeRequest(from record: Left) -> HasManyThroughRightRequest<Left, Middle, Right> {
        return HasManyThroughRightRequest(record: record, association: self)
    }
}

extension MutablePersistable {
    public func makeRequest<Middle, Right>(_ association: HasManyThroughAssociation<Self, Middle, Right>) -> HasManyThroughRightRequest<Self, Middle, Right> where Middle: TableMapping, Right: TableMapping {
        return association.makeRequest(from: self)
    }
    
    public func fetchCursor<Middle, Right>(_ db: Database, _ association: HasManyThroughAssociation<Self, Middle, Right>) throws -> DatabaseCursor<Right> where Middle: TableMapping, Right: TableMapping & RowConvertible {
        return try association.makeRequest(from: self).fetchCursor(db)
    }
    
    public func fetchAll<Middle, Right>(_ db: Database, _ association: HasManyThroughAssociation<Self, Middle, Right>) throws -> [Right] where Middle: TableMapping, Right: TableMapping & RowConvertible {
        return try association.makeRequest(from: self).fetchAll(db)
    }
    
    public func fetchOne<Middle, Right>(_ db: Database, _ association: HasManyThroughAssociation<Self, Middle, Right>) throws -> Right? where Middle: TableMapping, Right: TableMapping & RowConvertible {
        return try association.makeRequest(from: self).fetchOne(db)
    }
}
