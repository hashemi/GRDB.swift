public struct HasManyThroughJoinedRequest<Left: TableMapping, Middle: TableMapping, Right: TableMapping> {
    var leftRequest: QueryInterfaceRequest<Left>
    let association: HasManyThroughAssociation<Left, Middle, Right>
}

extension HasManyThroughJoinedRequest : LeftRequestDerivable {
    typealias LeftRowDecoder = Left
    
    func mapLeftRequest(_ transform: (QueryInterfaceRequest<Left>) -> (QueryInterfaceRequest<Left>)) -> HasManyThroughJoinedRequest<Left, Middle, Right> {
        return HasManyThroughJoinedRequest(leftRequest: transform(leftRequest), association: association)
    }
}

extension HasManyThroughJoinedRequest : TypedRequest {
    public typealias RowDecoder = JoinedPair<Left, Right>
    
    public func prepare(_ db: Database) throws -> (SelectStatement, RowAdapter?) {
        // TODO: don't alias unless necessary
        let leftQualifier = SQLSourceQualifier(alias: "left")
        let middleQualifier = SQLSourceQualifier(alias: "middle")
        let rightQualifier = SQLSourceQualifier(alias: "right")
        
        // SELECT * FROM left ... -> SELECT left.* FROM left ...
        let leftQuery = leftRequest.query.qualified(by: leftQualifier)
        
        // SELECT * FROM left ... -> SELECT left.* FROM left ...
        let middleQuery = association.middleRequest.query.qualified(by: middleQualifier)
        
        // SELECT * FROM right ... -> SELECT right.* FROM right ...
        let rightQuery = association.rightRequest.query.qualified(by: rightQualifier)
        
        // SELECT left.*, right.*
        let joinedSelection = leftQuery.selection + rightQuery.selection
        
        // ... FROM left JOIN middle
        guard let leftSource = leftQuery.source else { fatalError("Support for sourceless joins is not implemented") }
        guard let middleSource = middleQuery.source else { fatalError("Support for sourceless joins is not implemented") }
        guard let rightSource = rightQuery.source else { fatalError("Support for sourceless joins is not implemented") }
        
        let joinedSource = try SQLSource.joined(SQLSource.JoinDefinition(
            joinOp: .join,
            leftSource: SQLSource.joined(SQLSource.JoinDefinition(
                joinOp: .join,
                leftSource: leftSource,
                rightSource: middleSource,
                onExpression: middleQuery.whereExpression,
                mapping: association.middleMapping(db))),
            rightSource: rightSource,
            onExpression: rightQuery.whereExpression,
            mapping: association.rightMapping(db)))
        
        // ORDER BY left.***, right.***
        let joinedOrderings = leftQuery.eventuallyReversedOrderings + rightQuery.eventuallyReversedOrderings
        
        // Define row scopes
        let leftCount = try leftQuery.numberOfColumns(db)
        let rightCount = try rightQuery.numberOfColumns(db)
        let joinedAdapter = ScopeAdapter([
            // Left columns start at index 0
            RowDecoder.leftScope: RangeRowAdapter(0..<leftCount),
            // Right columns start after left columns
            RowDecoder.rightScope: RangeRowAdapter(leftCount..<(leftCount + rightCount))])
        
        return try QueryInterfaceSelectQueryDefinition(
            select: joinedSelection,
            isDistinct: leftQuery.isDistinct,
            from: joinedSource,
            filter: leftQuery.whereExpression,
            groupBy: leftQuery.groupByExpressions,
            orderBy: joinedOrderings,
            isReversed: false,
            having: leftQuery.havingExpression,
            limit: leftQuery.limit)
            .adapted { _ in joinedAdapter }
            .prepare(db)
    }
}

extension QueryInterfaceRequest where RowDecoder: TableMapping {
    public func joined<Middle, Right>(with association: HasManyThroughAssociation<RowDecoder, Middle, Right>) -> HasManyThroughJoinedRequest<RowDecoder, Middle, Right> where Middle: TableMapping, Right: TableMapping {
        return HasManyThroughJoinedRequest(leftRequest: self, association: association)
    }
}

extension TableMapping {
    public static func joined<Middle, Right>(with association: HasManyThroughAssociation<Self, Middle, Right>) -> HasManyThroughJoinedRequest<Self, Middle, Right> where Middle: TableMapping, Right: TableMapping {
        return all().joined(with: association)
    }
}
