// Remove RightRequestDerivable conformance once https://github.com/apple/swift-evolution/blob/master/proposals/0143-conditional-conformances.md is implemented
public struct HasManyThroughAnnotatedRequest<MiddleAssociation: Association, RightAssociation: Association, Annotation> where MiddleAssociation.RightAssociated == RightAssociation.LeftAssociated, RightAssociation: RightRequestDerivable, RightAssociation.RightRowDecoder == RightAssociation.RightAssociated {
    var leftRequest: QueryInterfaceRequest<MiddleAssociation.LeftAssociated>
    let annotation: HasManyThroughAnnotation<MiddleAssociation, RightAssociation, Annotation>
}

extension HasManyThroughAnnotatedRequest : LeftRequestDerivable {
    typealias LeftRowDecoder = MiddleAssociation.LeftAssociated
    
    func mapLeftRequest(_ transform: (QueryInterfaceRequest<MiddleAssociation.LeftAssociated>) -> (QueryInterfaceRequest<MiddleAssociation.LeftAssociated>)) -> HasManyThroughAnnotatedRequest<MiddleAssociation, RightAssociation, Annotation> {
        return HasManyThroughAnnotatedRequest(leftRequest: transform(leftRequest), annotation: annotation)
    }
}

extension HasManyThroughAnnotatedRequest : TypedRequest {
    public typealias RowDecoder = JoinedPair<MiddleAssociation.LeftAssociated, Annotation>
    
    public func prepare(_ db: Database) throws -> (SelectStatement, RowAdapter?) {
        var leftQualifier = SQLSourceQualifier()
        var middleQualifier = SQLSourceQualifier()
        var rightQualifier = SQLSourceQualifier()
        
        // SELECT * FROM left ... -> SELECT left.* FROM left ...
        let leftQuery = leftRequest.query.qualified(by: &leftQualifier)
        
        // SELECT * FROM middle ... -> SELECT middle.* FROM middle ...
        let middleQuery = annotation.association.middleAssociation.rightRequest.query.qualified(by: &middleQualifier)
        
        // SELECT * FROM right ... -> SELECT right.* FROM right ...
        let rightQuery = annotation.association.rightAssociation.rightRequest.query.qualified(by: &rightQualifier)
        
        // SELECT left.*, right.annotation
        let joinedSelection = try leftQuery.selection + [annotation.expression(db).qualified(by: rightQualifier)]
        
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
                mapping: annotation.association.middleAssociation.mapping(db))),
            rightSource: rightSource,
            onExpression: rightQuery.whereExpression,
            mapping: annotation.association.rightAssociation.mapping(db)))
        
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
        
        // Define row scopes
        let leftCount = try leftQuery.numberOfColumns(db)
        let rightCount = 1
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
            groupBy: joinedGroupByExpressions,
            orderBy: leftQuery.orderings,
            isReversed: leftQuery.isReversed,
            having: leftQuery.havingExpression,
            limit: leftQuery.limit)
            .adapted { _ in joinedAdapter }
            .prepare(db)
    }
}

extension QueryInterfaceRequest where RowDecoder: TableMapping {
    public func annotated<MiddleAssociation, RightAssociation, Annotation>(with annotation: HasManyThroughAnnotation<MiddleAssociation, RightAssociation, Annotation>) -> HasManyThroughAnnotatedRequest<MiddleAssociation, RightAssociation, Annotation> where MiddleAssociation.LeftAssociated == RowDecoder {
        return HasManyThroughAnnotatedRequest(leftRequest: self, annotation: annotation)
    }
}

extension TableMapping {
    public static func annotated<MiddleAssociation, RightAssociation, Annotation>(with annotation: HasManyThroughAnnotation<MiddleAssociation, RightAssociation, Annotation>) -> HasManyThroughAnnotatedRequest<MiddleAssociation, RightAssociation, Annotation> where MiddleAssociation.LeftAssociated == Self {
        return all().annotated(with: annotation)
    }
}
