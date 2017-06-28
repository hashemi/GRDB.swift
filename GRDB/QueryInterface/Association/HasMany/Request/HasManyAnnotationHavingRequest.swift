public struct HasManyAnnotationPredicateRequest<Left, Right, Annotation> where
    Left: TableMapping,
    Right: TableMapping
{
    typealias LeftRequest = QueryInterfaceRequest<Left>
    
    var leftRequest: LeftRequest
    let annotationPredicate: HasManyAnnotationPredicate<Left, Right, Annotation>
}

extension HasManyAnnotationPredicateRequest : LeftRequestDerivable {
    func mapLeftRequest(_ transform: (LeftRequest) -> (LeftRequest)) -> HasManyAnnotationPredicateRequest<Left, Right, Annotation> {
        return HasManyAnnotationPredicateRequest(
            leftRequest: transform(leftRequest),
            annotationPredicate: annotationPredicate)
    }
}

extension HasManyAnnotationPredicateRequest : TypedRequest {
    public typealias RowDecoder = Left
    
    public func prepare(_ db: Database) throws -> (SelectStatement, RowAdapter?) {
        var leftQualifier = SQLSourceQualifier()
        var rightQualifier = SQLSourceQualifier()
        
        // SELECT * FROM left ... -> SELECT left.* FROM left ...
        let leftQuery = leftRequest.query.qualified(by: &leftQualifier)
        
        // SELECT * FROM right ... -> SELECT right.* FROM right ...
        let rightQuery = annotationPredicate.annotation.association.rightRequest.query.qualified(by: &rightQualifier)
        
        // Join sources: SELECT ... FROM left LEFT JOIN right
        let joinedSource = try SQLSource(
            leftQuery.source,
            .leftJoin,
            rightQuery.source,
            on: annotationPredicate.annotation.association.mapping(db),
            and: rightQuery.whereExpression)
        
        // ... GROUP BY left.id
        guard let leftTableName = leftQuery.source.tableName else {
            fatalError("Can't annotate tableless query")
        }
        let pkColumns = (try db.primaryKey(leftTableName)?.columns ?? (Left.selectsRowID ? [Column.rowID.name] : []))
            .map { Column($0).qualified(by: leftQualifier) as SQLExpression }
        guard !pkColumns.isEmpty else {
            fatalError("Can't annotate table without primary key")
        }
        let joinedGroupByExpressions = pkColumns + leftQuery.groupByExpressions
        
        // Having: HAVING annotationExpression
        let rightHavingExpression = try annotationPredicate.predicate(annotationPredicate.annotation.expression(db)).qualified(by: rightQualifier)
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
    public func filter<Right, Annotation>(_ annotationPredicate: HasManyAnnotationPredicate<RowDecoder, Right, Annotation>)
        -> HasManyAnnotationPredicateRequest<RowDecoder, Right, Annotation>
        where Right: TableMapping
    {
        return HasManyAnnotationPredicateRequest(leftRequest: self, annotationPredicate: annotationPredicate)
    }
}

extension TableMapping {
    public static func filter<Right, Annotation>(_ annotationPredicate: HasManyAnnotationPredicate<Self, Right, Annotation>)
        -> HasManyAnnotationPredicateRequest<Self, Right, Annotation>
        where Right: TableMapping
    {
        return all().filter(annotationPredicate)
    }
}
