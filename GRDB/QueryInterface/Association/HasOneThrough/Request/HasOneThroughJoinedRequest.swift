public struct HasOneThroughJoinedRequest<MiddleAssociation, RightAssociation> where
    MiddleAssociation: AssociationToOne,
    RightAssociation: RightRequestDerivable, // TODO: Remove once SE-0143 is implemented
    RightAssociation: AssociationToOne,
    MiddleAssociation.RightAssociated == RightAssociation.LeftAssociated
{
    var leftRequest: QueryInterfaceRequest<MiddleAssociation.LeftAssociated>
    let association: HasOneThroughAssociation<MiddleAssociation, RightAssociation>
}

extension HasOneThroughJoinedRequest : LeftRequestDerivable {
    typealias LeftRequest = QueryInterfaceRequest<MiddleAssociation.LeftAssociated>
    
    func mapLeftRequest(_ transform: (QueryInterfaceRequest<MiddleAssociation.LeftAssociated>) -> (QueryInterfaceRequest<MiddleAssociation.LeftAssociated>)) -> HasOneThroughJoinedRequest<MiddleAssociation, RightAssociation> {
        return HasOneThroughJoinedRequest(leftRequest: transform(leftRequest), association: association)
    }
}

extension HasOneThroughJoinedRequest : TypedRequest {
    public typealias RowDecoder = JoinedPair<MiddleAssociation.LeftAssociated, RightAssociation.RightAssociated?>
    
    public func prepare(_ db: Database) throws -> (SelectStatement, RowAdapter?) {
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
        
        // ... FROM left JOIN middle JOIN right
        let joinedSource = try SQLSource.joined(SQLSource.JoinDefinition(
            joinOp: .join,
            leftSource: SQLSource.joined(SQLSource.JoinDefinition(
                joinOp: .join,
                leftSource: leftQuery.source,
                rightSource: middleQuery.source,
                onExpression: middleQuery.whereExpression,
                mapping: association.middleAssociation.mapping(db))),
            rightSource: rightQuery.source,
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
            .adapted(joinedAdapter)
            .prepare(db)
    }
}

extension QueryInterfaceRequest where RowDecoder: TableMapping {
    public func joined<MiddleAssociation, RightAssociation>(with association: HasOneThroughAssociation<MiddleAssociation, RightAssociation>)
        -> HasOneThroughJoinedRequest<MiddleAssociation, RightAssociation>
        where MiddleAssociation.LeftAssociated == RowDecoder
    {
        return HasOneThroughJoinedRequest(leftRequest: self, association: association)
    }
}

extension TableMapping {
    public static func joined<MiddleAssociation, RightAssociation>(with association: HasOneThroughAssociation<MiddleAssociation, RightAssociation>)
        -> HasOneThroughJoinedRequest<MiddleAssociation, RightAssociation>
        where MiddleAssociation.LeftAssociated == Self
    {
        return all().joined(with: association)
    }
}
