// Remove RightRequestDerivable conformance once https://github.com/apple/swift-evolution/blob/master/proposals/0143-conditional-conformances.md is implemented
public struct HasOneThroughRightRequest<MiddleAssociation, RightAssociation> where
    MiddleAssociation: AssociationToOne,
    RightAssociation: RightRequestDerivable, // TODO: Remove once SE-0143 is implemented
    RightAssociation: AssociationToOne,
    MiddleAssociation.RightAssociated == RightAssociation.LeftAssociated,
    MiddleAssociation.LeftAssociated: MutablePersistable
{
    let record: MiddleAssociation.LeftAssociated
    let association: HasOneThroughAssociation<MiddleAssociation, RightAssociation>
}

// Derive conditional conformance to RightRequestDerivableonce once SE-0143 is implemented
extension HasOneThroughRightRequest : RightRequestDerivable {
    public typealias RightRequest = RightAssociation.RightRequest
    
    public func mapRightRequest(_ transform: (RightRequest) -> RightRequest) -> HasOneThroughRightRequest<MiddleAssociation, RightAssociation> {
        return HasOneThroughRightRequest(record: record, association: association.mapRightRequest(transform))
    }
}

extension HasOneThroughRightRequest : TypedRequest {
    public typealias RowDecoder = RightAssociation.RightAssociated
    
    public func prepare(_ db: Database) throws -> (SelectStatement, RowAdapter?) {
        let middleMapping = try association.middleAssociation.mapping(db)
        let container = PersistenceContainer(record)
        let rowValue = RowValue(middleMapping.map { container[caseInsensitive: $0.left]?.databaseValue ?? .null })
        
        var middleQualifier = SQLSourceQualifier()
        var rightQualifier = SQLSourceQualifier()
        
        // SELECT * FROM middle ... -> SELECT middle.* FROM middle WHERE middle.leftId = left.id ...
        let middleQuery = association.middleAssociation.rightRequest.filter(middleMapping.map { Column($0.right) } == rowValue).query.qualified(by: &middleQualifier)
        
        // SELECT * FROM right ... -> SELECT right.* FROM right ...
        let rightQuery = association.rightAssociation.rightRequest.query.qualified(by: &rightQualifier)
        
        // ... FROM right JOIN middle
        let joinedSource = try SQLSource(
            rightQuery.source,
            .innerJoin,
            middleQuery.source,
            on: association.rightAssociation.reversedMapping(db),
            and: middleQuery.whereExpression)
        
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

extension HasOneThroughAssociation where MiddleAssociation.LeftAssociated: MutablePersistable {
    func makeRequest(from record: MiddleAssociation.LeftAssociated)
        -> HasOneThroughRightRequest<MiddleAssociation, RightAssociation>
    {
        return HasOneThroughRightRequest(record: record, association: self)
    }
}

extension MutablePersistable {
    public func makeRequest<MiddleAssociation, RightAssociation>(_ association: HasOneThroughAssociation<MiddleAssociation, RightAssociation>)
        -> HasOneThroughRightRequest<MiddleAssociation, RightAssociation>
        where MiddleAssociation.LeftAssociated == Self
    {
        return association.makeRequest(from: self)
    }
    
    public func fetchOne<MiddleAssociation, RightAssociation>(_ db: Database, _ association: HasOneThroughAssociation<MiddleAssociation, RightAssociation>) throws
        -> RightAssociation.RightAssociated?
        where
        MiddleAssociation.LeftAssociated == Self,
        RightAssociation.RightAssociated: RowConvertible
    {
        return try association.makeRequest(from: self).fetchOne(db)
    }
}
