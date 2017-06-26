public struct HasManyAnnotatedRequest<Left: TableMapping, Right: TableMapping, Annotation> {
    var leftRequest: QueryInterfaceRequest<Left>
    let annotation: HasManyAnnotation<Left, Right, Annotation>
}

extension HasManyAnnotatedRequest : LeftRequestDerivable {
    typealias LeftRowDecoder = Left
    
    func mapLeftRequest(_ transform: (QueryInterfaceRequest<Left>) -> (QueryInterfaceRequest<Left>)) -> HasManyAnnotatedRequest<Left, Right, Annotation> {
        return HasManyAnnotatedRequest(leftRequest: transform(leftRequest), annotation: annotation)
    }
}

extension HasManyAnnotatedRequest : TypedRequest {
    public typealias RowDecoder = JoinedPair<Left, Annotation>
    
    public func prepare(_ db: Database) throws -> (SelectStatement, RowAdapter?) {
        var leftQualifier = SQLSourceQualifier()
        var rightQualifier = SQLSourceQualifier()
        
        // SELECT * FROM left ... -> SELECT left.* FROM left ...
        let leftQuery = leftRequest.query.qualified(by: &leftQualifier)
        
        // SELECT * FROM right ... -> SELECT right.* FROM right ...
        let rightQuery = annotation.association.rightRequest.query.qualified(by: &rightQualifier)
        
        // SELECT left.*, right.annotation
        let joinedSelection = try leftQuery.selection + [annotation.expression(db).qualified(by: rightQualifier)]
        
        // ... FROM left LEFT JOIN right
        guard let leftSource = leftQuery.source else { fatalError("Support for sourceless joins is not implemented") }
        guard let rightSource = rightQuery.source else { fatalError("Support for sourceless joins is not implemented") }
        let joinedSource = try SQLSource.joined(SQLSource.JoinDefinition(
            joinOp: .leftJoin,
            leftSource: leftSource,
            rightSource: rightSource,
            onExpression: rightQuery.whereExpression,
            mapping: annotation.association.mapping(db)))
        
        // ... GROUP BY left.id
        guard let leftTableName = leftQuery.source?.tableName else {
            fatalError("Can't annotate tableless query")
        }
        let pkColumns = (try db.primaryKey(leftTableName)?.columns ?? (Left.selectsRowID ? [Column.rowID.name] : []))
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
    public func annotated<Right, Annotation>(with annotation: HasManyAnnotation<RowDecoder, Right, Annotation>) -> HasManyAnnotatedRequest<RowDecoder, Right, Annotation> where Right: TableMapping {
        return HasManyAnnotatedRequest(leftRequest: self, annotation: annotation)
    }
}

extension TableMapping {
    public static func annotated<Right, Annotation>(with annotation: HasManyAnnotation<Self, Right, Annotation>) -> HasManyAnnotatedRequest<Self, Right, Annotation> where Right: TableMapping {
        return all().annotated(with: annotation)
    }
}
