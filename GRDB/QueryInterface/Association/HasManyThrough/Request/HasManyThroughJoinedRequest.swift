public struct HasManyThroughJoinedRequest<MiddleAssociation, RightAssociation> where
    MiddleAssociation: Association,
    RightAssociation: Association,
    RightAssociation: RequestDerivableWrapper, // TODO: Remove once SE-0143 is implemented
    RightAssociation.LeftAssociated == MiddleAssociation.RightAssociated
{
    public typealias WrappedRequest = QueryInterfaceRequest<MiddleAssociation.LeftAssociated>
    
    var leftRequest: WrappedRequest
    let association: HasManyThroughAssociation<MiddleAssociation, RightAssociation>
}

// TODO: Derive conditional conformance to RequestDerivableWrapper once once SE-0143 is implemented
extension HasManyThroughJoinedRequest : RequestDerivableWrapper {
    public func mapRequest(_ transform: (WrappedRequest) -> (WrappedRequest)) -> HasManyThroughJoinedRequest {
        return HasManyThroughJoinedRequest(
            leftRequest: transform(leftRequest),
            association: association)
    }
}

extension HasManyThroughJoinedRequest : TypedRequest {
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
        
        // ... FROM left JOIN middle
        let joinedSource = try leftQuery.source.join(
            .inner,
            on: association.middleAssociation.mapping(db),
            and: middleQuery.whereExpression,
            to: middleQuery.source.join(
                .inner,
                on: association.rightAssociation.mapping(db),
                and: rightQuery.whereExpression,
                to: rightQuery.source))
        
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
    public func joined<MiddleAssociation, RightAssociation>(with association: HasManyThroughAssociation<MiddleAssociation, RightAssociation>)
        -> HasManyThroughJoinedRequest<MiddleAssociation, RightAssociation>
        where MiddleAssociation.LeftAssociated == RowDecoder
    {
        return HasManyThroughJoinedRequest(leftRequest: self, association: association)
    }
}

extension TableMapping {
    public static func joined<MiddleAssociation, RightAssociation>(with association: HasManyThroughAssociation<MiddleAssociation, RightAssociation>)
        -> HasManyThroughJoinedRequest<MiddleAssociation, RightAssociation>
        where MiddleAssociation.LeftAssociated == Self
    {
        return all().joined(with: association)
    }
}
