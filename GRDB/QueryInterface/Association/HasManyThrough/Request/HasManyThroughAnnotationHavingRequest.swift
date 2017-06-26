// Remove RightRequestDerivable conformance once https://github.com/apple/swift-evolution/blob/master/proposals/0143-conditional-conformances.md is implemented
public struct HasManyThroughAnnotationHavingRequest<MiddleAssociation, RightAssociation, Annotation>
    where
    MiddleAssociation: Association,
    RightAssociation: Association,
    RightAssociation: RightRequestDerivable,
    RightAssociation.LeftAssociated == MiddleAssociation.RightAssociated,
    RightAssociation.RightAssociated == RightAssociation.RightRowDecoder
{
    var leftRequest: QueryInterfaceRequest<MiddleAssociation.LeftAssociated>
    let annotationHavingExpression: HasManyThroughAnnotationHavingExpression<MiddleAssociation, RightAssociation, Annotation>
}

extension HasManyThroughAnnotationHavingRequest : LeftRequestDerivable {
    typealias LeftRowDecoder = MiddleAssociation.LeftAssociated
    
    func mapLeftRequest(_ transform: (QueryInterfaceRequest<MiddleAssociation.LeftAssociated>) -> (QueryInterfaceRequest<MiddleAssociation.LeftAssociated>)) -> HasManyThroughAnnotationHavingRequest<MiddleAssociation, RightAssociation, Annotation> {
        return HasManyThroughAnnotationHavingRequest(leftRequest: transform(leftRequest), annotationHavingExpression: annotationHavingExpression)
    }
}

extension HasManyThroughAnnotationHavingRequest : TypedRequest {
    public typealias RowDecoder = MiddleAssociation.LeftAssociated
    
    public func prepare(_ db: Database) throws -> (SelectStatement, RowAdapter?) {
        var leftQualifier = SQLSourceQualifier()
        var middleQualifier = SQLSourceQualifier()
        var rightQualifier = SQLSourceQualifier()
        
        // SELECT * FROM left ... -> SELECT left.* FROM left ...
        let leftQuery = leftRequest.query.qualified(by: &leftQualifier)
        
        // SELECT * FROM middle ... -> SELECT middle.* FROM middle ...
        let middleQuery = annotationHavingExpression.annotation.association.middleAssociation.rightRequest.query.qualified(by: &middleQualifier)
        
        // SELECT * FROM right ... -> SELECT right.* FROM right ...
        let rightQuery = annotationHavingExpression.annotation.association.rightAssociation.rightRequest.query.qualified(by: &rightQualifier)
        
        // ... FROM left LEFT JOIN middle LEFT JOIN right
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
                mapping: annotationHavingExpression.annotation.association.middleAssociation.mapping(db))),
            rightSource: rightSource,
            onExpression: rightQuery.whereExpression,
            mapping: annotationHavingExpression.annotation.association.rightAssociation.mapping(db)))
        
        // ... GROUP BY left.id
        guard let leftTableName = leftQuery.source?.tableName else {
            fatalError("Can't annotate tableless query")
        }
        let pkColumns = (try db.primaryKey(leftTableName)?.columns ?? (MiddleAssociation.LeftAssociated.selectsRowID ? [Column.rowID.name] : []))
            .map { Column($0).qualified(by: leftQualifier) as SQLExpression }
        guard !pkColumns.isEmpty else {
            fatalError("Can't annotate table without primary key")
        }
        let joinedGroupByExpressions = pkColumns + leftQuery.groupByExpressions
        
        // Having: HAVING annotationExpression
        let rightHavingExpression = try annotationHavingExpression.havingExpression(annotationHavingExpression.annotation.expression(db)).qualified(by: rightQualifier)
        let joinedHavingExpression = (leftQuery.havingExpression.map { rightHavingExpression && $0 } ?? rightHavingExpression).qualified(by: rightQualifier)
        
        return try QueryInterfaceSelectQueryDefinition(
            select: leftQuery.selection,
            isDistinct: leftQuery.isDistinct,   // TODO: test
            from: joinedSource,
            filter: leftQuery.whereExpression,  // TODO: test
            groupBy: joinedGroupByExpressions,
            orderBy: leftQuery.orderings,       // TODO: test
            isReversed: leftQuery.isReversed,   // TODO: test
            having: joinedHavingExpression,
            limit: leftQuery.limit)             // TODO: test
            .prepare(db)
    }
}

extension QueryInterfaceRequest where RowDecoder: TableMapping {
    public func filter<MiddleAssociation, RightAssociation, Annotation>(_ expression: HasManyThroughAnnotationHavingExpression<MiddleAssociation, RightAssociation, Annotation>) -> HasManyThroughAnnotationHavingRequest<MiddleAssociation, RightAssociation, Annotation> where MiddleAssociation.LeftAssociated == RowDecoder {
        return HasManyThroughAnnotationHavingRequest(leftRequest: self, annotationHavingExpression: expression)
    }
}

extension TableMapping {
    public static func filter<MiddleAssociation, RightAssociation, Annotation>(_ expression: HasManyThroughAnnotationHavingExpression<MiddleAssociation, RightAssociation, Annotation>) -> HasManyThroughAnnotationHavingRequest<MiddleAssociation, RightAssociation, Annotation> where MiddleAssociation.LeftAssociated == Self {
        return all().filter(expression)
    }
}
