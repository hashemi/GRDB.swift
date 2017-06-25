public struct HasManyAnnotationHavingRequest<Left: TableMapping, Right: TableMapping, Annotation> {
    var leftRequest: QueryInterfaceRequest<Left>
    let annotationHavingExpression: HasManyAnnotationHavingExpression<Left, Right, Annotation>
}

extension HasManyAnnotationHavingRequest : LeftRequestDerivable {
    typealias LeftRowDecoder = Left
    
    func mapLeftRequest(_ transform: (QueryInterfaceRequest<Left>) -> (QueryInterfaceRequest<Left>)) -> HasManyAnnotationHavingRequest<Left, Right, Annotation> {
        return HasManyAnnotationHavingRequest(leftRequest: transform(leftRequest), annotationHavingExpression: annotationHavingExpression)
    }
}

extension HasManyAnnotationHavingRequest : TypedRequest {
    public typealias RowDecoder = Left
    
    public func prepare(_ db: Database) throws -> (SelectStatement, RowAdapter?) {
        // TODO: don't alias unless necessary
        let leftQualifier = SQLSourceQualifier(alias: "left")
        let rightQualifier = SQLSourceQualifier(alias: "right")
        
        // SELECT * FROM left ... -> SELECT left.* FROM left ...
        let leftQuery = leftRequest.query.qualified(by: leftQualifier)
        
        // SELECT * FROM right ... -> SELECT right.* FROM right ...
        let rightQuery = annotationHavingExpression.annotation.association.rightRequest.query.qualified(by: rightQualifier)
        
        // Join sources: SELECT ... FROM left LEFT JOIN right
        guard let leftSource = leftQuery.source else { fatalError("Support for sourceless joins is not implemented") }
        guard let rightSource = rightQuery.source else { fatalError("Support for sourceless joins is not implemented") }
        let joinedSource = try SQLSource.joined(SQLSource.JoinDefinition(
            joinOp: .leftJoin,
            leftSource: leftSource,
            rightSource: rightSource,
            onExpression: rightQuery.whereExpression,
            mapping: annotationHavingExpression.annotation.association.mapping(db)))
        
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
    public func filter<Right, Annotation>(_ expression: HasManyAnnotationHavingExpression<RowDecoder, Right, Annotation>) -> HasManyAnnotationHavingRequest<RowDecoder, Right, Annotation> where Right: TableMapping {
        return HasManyAnnotationHavingRequest(leftRequest: self, annotationHavingExpression: expression)
    }
}

extension TableMapping {
    public static func filter<Right, Annotation>(_ expression: HasManyAnnotationHavingExpression<Self, Right, Annotation>) -> HasManyAnnotationHavingRequest<Self, Right, Annotation> where Right: TableMapping {
        return all().filter(expression)
    }
}
