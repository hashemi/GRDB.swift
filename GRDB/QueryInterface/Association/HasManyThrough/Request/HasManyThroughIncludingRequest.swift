public struct HasManyThroughIncludingRequest<Left, MiddleAssociation, RightAssociation> where
    Left: RequestDerivable, // TODO: Remove once SE-0143 is implemented
    Left: TypedRequest,
    Left.RowDecoder: TableMapping,
    MiddleAssociation: Association,
    MiddleAssociation.LeftAssociated == Left.RowDecoder,
    RightAssociation: Association,
    RightAssociation: RightRequestDerivable, // TODO: Remove once SE-0143 is implemented
    RightAssociation.LeftAssociated == MiddleAssociation.RightAssociated
{
    var leftRequest: Left
    let association: HasManyThroughAssociation<MiddleAssociation, RightAssociation>
}

// Derive conditional conformance to LeftRequestDerivable once SE-0143 is implemented
extension HasManyThroughIncludingRequest : LeftRequestDerivable {
    typealias LeftRequest = Left
    
    func mapLeftRequest(_ transform: (LeftRequest) -> (LeftRequest)) -> HasManyThroughIncludingRequest<Left, MiddleAssociation, RightAssociation> {
        return HasManyThroughIncludingRequest(
            leftRequest: transform(leftRequest),
            association: association)
    }
}

extension HasManyThroughIncludingRequest where Left.RowDecoder: RowConvertible, RightAssociation.RightAssociated : RowConvertible {
    public func fetchAll(_ db: Database) throws -> [(left: Left.RowDecoder, right: [RightAssociation.RightAssociated])] {
        let middleMapping = try association.middleAssociation.mapping(db)
        guard middleMapping.count == 1 else {
            fatalError("not implemented: support for compound foreign keys")
        }
        let leftKeyColumn = middleMapping[0].left
        let middleKeyColumn = middleMapping[0].right
        
        var result: [(left: Left.RowDecoder, right: [RightAssociation.RightAssociated])] = []
        var resultIndexes : [DatabaseValue: [Int]] = [:]
        
        // SELECT * FROM left...
        do {
            // Where is the left key?
            let (cursor, layout) = try Row.fetchCursorWithLayout(db, leftRequest)
            guard let keyIndex = layout.layoutIndex(ofColumn: leftKeyColumn) else {
                fatalError("Column \(Left.RowDecoder.databaseTableName).\(leftKeyColumn) is not selected")
            }
            
            try cursor.enumerated().forEach { (recordIndex, row) in
                let left = Left.RowDecoder(row: row)
                let key: DatabaseValue = row.value(atIndex: keyIndex)
                if !key.isNull {
                    if resultIndexes[key] == nil { resultIndexes[key] = [] }
                    resultIndexes[key]!.append(recordIndex)
                }
                result.append((left: left, right: []))
            }
        }
        
        if result.isEmpty {
            return result
        }
        
        var middleQualifier = SQLSourceQualifier()
        var rightQualifier = SQLSourceQualifier()
        
        // SELECT * FROM middle ... -> SELECT middle.* FROM middle WHERE middle.leftId IN (...)
        let middleQuery = association.middleAssociation.rightRequest
            .filter(resultIndexes.keys.contains(Column(middleKeyColumn)))
            .query
            .qualified(by: &middleQualifier)

        // SELECT * FROM right ... -> SELECT right.* FROM right ...
        let rightQuery = association.rightAssociation.rightRequest.query.qualified(by: &rightQualifier)
        
        // SELECT middle.leftId, right.* FROM right...
        let joinedSelection = [Column(middleKeyColumn).qualified(by: middleQualifier)] + rightQuery.selection
        
        // ... FROM right JOIN middle
        guard let middleSource = middleQuery.source else { fatalError("Support for sourceless joins is not implemented") }
        guard let rightSource = rightQuery.source else { fatalError("Support for sourceless joins is not implemented") }
        let joinedSource = try SQLSource.joined(SQLSource.JoinDefinition(
            joinOp: .join,
            leftSource: rightSource,
            rightSource: middleSource,
            onExpression: middleQuery.whereExpression,
            mapping: association.rightAssociation.mapping(db).map { (left: $0.right, right: $0.left ) }))
        
        // ORDER BY right.***, middle.***
        let joinedOrderings = rightQuery.eventuallyReversedOrderings + middleQuery.eventuallyReversedOrderings
        
        let joinedRequest = QueryInterfaceSelectQueryDefinition(
            select: joinedSelection,
            isDistinct: rightQuery.isDistinct,
            from: joinedSource,
            filter: rightQuery.whereExpression,
            groupBy: [],
            orderBy: joinedOrderings,
            isReversed: false,
            having: nil,
            limit: nil)
            .adapted(ScopeAdapter([
                // Right columns start after left key: SELECT middle.leftId, right.* FROM right...
                "right": SuffixRowAdapter(fromIndex: 1)]))

        let cursor = try Row.fetchCursor(db, joinedRequest)

        while let row = try cursor.next() {
            let rightRow = row.scoped(on: "right")!
            let key: DatabaseValue = row.value(atIndex: 0)
            assert(!key.isNull)
            let indexes = resultIndexes[key]! // indexes have been recorded during leftRequest iteration
            for index in indexes {
                // instanciate for each index, in order to never reuse references
                let right = RightAssociation.RightAssociated(row: rightRow)
                result[index].right.append(right)
            }
        }
        
        return result
    }
}

extension TypedRequest where Self: RequestDerivable, RowDecoder: TableMapping {
    public func including<MiddleAssociation, RightAssociation>(_ association: HasManyThroughAssociation<MiddleAssociation, RightAssociation>)
        -> HasManyThroughIncludingRequest<Self, MiddleAssociation, RightAssociation>
        where MiddleAssociation.LeftAssociated == RowDecoder
    {
        return HasManyThroughIncludingRequest(leftRequest: self, association: association)
    }
}

extension TableMapping {
    public static func including<MiddleAssociation, RightAssociation>(_ association: HasManyThroughAssociation<MiddleAssociation, RightAssociation>)
        -> HasManyThroughIncludingRequest<QueryInterfaceRequest<Self>, MiddleAssociation, RightAssociation>
        where MiddleAssociation.LeftAssociated == Self
    {
        return all().including(association)
    }
}

extension HasManyThroughIncludingRequest where Left: QueryInterfaceRequestConvertible {
    public func filter<Right2, Annotation2>(_ annotationPredicate: HasManyAnnotationPredicate<Left.RowDecoder, Right2, Annotation2>)
        -> HasManyThroughIncludingRequest<HasManyAnnotationPredicateRequest<Left.RowDecoder, Right2, Annotation2>, MiddleAssociation, RightAssociation>
        where Right2: TableMapping
    {
        // Use type inference when Swift is able to do it
        return HasManyThroughIncludingRequest<HasManyAnnotationPredicateRequest<Left.RowDecoder, Right2, Annotation2>, MiddleAssociation, RightAssociation>(
            leftRequest: leftRequest.queryInterfaceRequest.filter(annotationPredicate),
            association: association)
    }
    
    public func filter<MiddleAssociation2, RightAssociation2, Annotation2>(_ annotationPredicate: HasManyThroughAnnotationPredicate<MiddleAssociation2, RightAssociation2, Annotation2>)
        -> HasManyThroughIncludingRequest<HasManyThroughAnnotationPredicateRequest<MiddleAssociation2, RightAssociation2, Annotation2>, MiddleAssociation, RightAssociation>
        where Left.RowDecoder == MiddleAssociation2.LeftAssociated
    {
        // Use type inference when Swift is able to do it
        return HasManyThroughIncludingRequest<HasManyThroughAnnotationPredicateRequest<MiddleAssociation2, RightAssociation2, Annotation2>, MiddleAssociation, RightAssociation>(
            leftRequest: leftRequest.queryInterfaceRequest.filter(annotationPredicate),
            association: association)
    }
}
