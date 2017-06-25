// Remove RightRequestDerivable conformance once https://github.com/apple/swift-evolution/blob/master/proposals/0143-conditional-conformances.md is implemented
public struct HasOneThroughLeftJoinedRequest<MiddleAssociation: AssociationToOne, RightAssociation: AssociationToOne> where MiddleAssociation.RightAssociated == RightAssociation.LeftAssociated, RightAssociation: RightRequestDerivable, RightAssociation.RightRowDecoder == RightAssociation.RightAssociated {
    var leftRequest: QueryInterfaceRequest<MiddleAssociation.LeftAssociated>
    let association: HasOneThroughAssociation<MiddleAssociation, RightAssociation>
}

extension HasOneThroughLeftJoinedRequest : LeftRequestDerivable {
    typealias LeftRowDecoder = MiddleAssociation.LeftAssociated
    
    func mapLeftRequest(_ transform: (QueryInterfaceRequest<LeftRowDecoder>) -> (QueryInterfaceRequest<LeftRowDecoder>)) -> HasOneThroughLeftJoinedRequest<MiddleAssociation, RightAssociation> {
        return HasOneThroughLeftJoinedRequest(leftRequest: transform(leftRequest), association: association)
    }
}

extension HasOneThroughLeftJoinedRequest : TypedRequest {
    public typealias RowDecoder = JoinedPair<MiddleAssociation.LeftAssociated, RightAssociation.RightAssociated?>
    
    public func prepare(_ db: Database) throws -> (SelectStatement, RowAdapter?) {
        // TODO: don't alias unless necessary
        var leftQualifier = SQLSourceQualifier()
        var middleQualifier = SQLSourceQualifier()
        var rightQualifier = SQLSourceQualifier()
        
        // SELECT * FROM left ... -> SELECT left.* FROM left ...
        let leftQuery = leftRequest.query.qualified(by: &leftQualifier)
        
        // SELECT * FROM middle ... -> SELECT middle.* FROM middle ...
        let middleQuery = association.middleAssociation.rightRequest.query.qualified(by: &middleQualifier)
        
        // SELECT * FROM right ... -> SELECT right.* FROM right ...
        let rightQuery = association.rightAssociation.rightRequest.query.qualified(by: &rightQualifier)
        
        // SELECT left.*, right.*
        let joinedSelection = leftQuery.selection + rightQuery.selection
        
        // ... FROM left JOIN middle
        guard let leftSource = leftQuery.source else { fatalError("Support for sourceless joins is not implemented") }
        guard let middleSource = middleQuery.source else { fatalError("Support for sourceless joins is not implemented") }
        guard let rightSource = rightQuery.source else { fatalError("Support for sourceless joins is not implemented") }
        
        let joinedSource = try SQLSource.joined(SQLSource.JoinDefinition(
            joinOp: .leftJoin,
            leftSource: SQLSource.joined(SQLSource.JoinDefinition(
                joinOp: .leftJoin,
                leftSource: leftSource,
                rightSource: middleSource,
                onExpression: middleQuery.whereExpression,
                mapping: association.middleAssociation.mapping(db))),
            rightSource: rightSource,
            onExpression: rightQuery.whereExpression,
            mapping: association.rightAssociation.mapping(db)))
        
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
    public func leftJoined<MiddleAssociation, RightAssociation>(with association: HasOneThroughAssociation<MiddleAssociation, RightAssociation>) -> HasOneThroughLeftJoinedRequest<MiddleAssociation, RightAssociation> where MiddleAssociation.LeftAssociated == RowDecoder {
        return HasOneThroughLeftJoinedRequest(leftRequest: self, association: association)
    }
}

extension TableMapping {
    public static func leftJoined<MiddleAssociation, RightAssociation>(with association: HasOneThroughAssociation<MiddleAssociation, RightAssociation>) -> HasOneThroughLeftJoinedRequest<MiddleAssociation, RightAssociation> where MiddleAssociation.LeftAssociated == Self {
        return all().leftJoined(with: association)
    }
}
