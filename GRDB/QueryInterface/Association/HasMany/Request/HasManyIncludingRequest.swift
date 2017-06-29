public struct HasManyIncludingRequest<Left, Right> where
    Left: RequestDerivable, // TODO: Remove once SE-0143 is implemented
    Left: TypedRequest,
    Left.RowDecoder: TableMapping,
    Right: TableMapping
{
    var leftRequest: Left
    let association: HasManyAssociation<Left.RowDecoder, Right>
}

// TODO: Derive conditional conformance to RequestDerivableWrapper once once SE-0143 is implemented
extension HasManyIncludingRequest : RequestDerivableWrapper {
    public typealias WrappedRequest = Left
    
    public func mapRequest(_ transform: (Left) -> (Left)) -> HasManyIncludingRequest {
        return HasManyIncludingRequest(
            leftRequest: transform(leftRequest),
            association: association)
    }
}

extension HasManyIncludingRequest where Left.RowDecoder: RowConvertible, Right: RowConvertible {
    public func fetchAll(_ db: Database) throws -> [(left: Left.RowDecoder, right: [Right])] {
        let mapping = try association.mapping(db)
        guard mapping.count == 1 else {
            fatalError("not implemented: support for compound foreign keys")
        }
        let leftKeyColumn = mapping[0].left
        let rightKeyColumn = mapping[0].right
        
        var result: [(left: Left.RowDecoder, right: [Right])] = []
        var resultIndexes : [DatabaseValue: Int] = [:]
        
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
                resultIndexes[key] = recordIndex
                result.append((left: left, right: []))
            }
        }
        
        if result.isEmpty {
            return result
        }
        
        // SELECT * FROM right WHERE leftId IN (...)
        do {
            guard mapping.count == 1 else {
                fatalError("not implemented: support for compound foreign keys")
            }
            let rightQuery = association.rightRequest.filter(resultIndexes.keys.contains(Column(rightKeyColumn))).query
            
            // Where is the right key?
            let (cursor, layout) = try Row.fetchCursorWithLayout(db, rightQuery)
            guard let keyIndex = layout.layoutIndex(ofColumn: rightKeyColumn) else {
                fatalError("not implemented: support for non-selected \(Right.databaseTableName).\(rightKeyColumn) column")
            }
            
            while let row = try cursor.next() {
                let right = Right(row: row)
                let key: DatabaseValue = row.value(atIndex: keyIndex)
                let index = resultIndexes[key]! // index has been recorded during leftRequest iteration
                result[index].right.append(right)
            }
        }
        
        return result
    }
}

extension TypedRequest where Self: RequestDerivable, RowDecoder: TableMapping {
    public func including<Right>(_ association: HasManyAssociation<RowDecoder, Right>)
        -> HasManyIncludingRequest<Self, Right>
        where Right: TableMapping
    {
        return HasManyIncludingRequest(leftRequest: self, association: association)
    }
}

extension TableMapping {
    public static func including<Right>(_ association: HasManyAssociation<Self, Right>)
        -> HasManyIncludingRequest<QueryInterfaceRequest<Self>, Right>
        where Right: TableMapping
    {
        return all().including(association)
    }
}

extension HasManyIncludingRequest where Left: QueryInterfaceRequestConvertible {
    public func filter<Right2, Annotation2>(_ annotationPredicate: HasManyAnnotationPredicate<Left.RowDecoder, Right2, Annotation2>)
        -> HasManyIncludingRequest<HasManyAnnotationPredicateRequest<Left.RowDecoder, Right2, Annotation2>, Right>
        where Right2: TableMapping
    {
        // TODO: Use type inference when Swift is able to do it
        return HasManyIncludingRequest<HasManyAnnotationPredicateRequest<Left.RowDecoder, Right2, Annotation2>, Right>(
            leftRequest: leftRequest.queryInterfaceRequest.filter(annotationPredicate),
            association: association)
    }
    
    public func filter<MiddleAssociation2, RightAssociation2, Annotation2>(_ annotationPredicate: HasManyThroughAnnotationPredicate<MiddleAssociation2, RightAssociation2, Annotation2>)
        -> HasManyIncludingRequest<HasManyThroughAnnotationPredicateRequest<MiddleAssociation2, RightAssociation2, Annotation2>, Right>
        where MiddleAssociation2.LeftAssociated == Left.RowDecoder
    {
        // TODO: Use type inference when Swift is able to do it
        return HasManyIncludingRequest<HasManyThroughAnnotationPredicateRequest<MiddleAssociation2, RightAssociation2, Annotation2>, Right>(
            leftRequest: leftRequest.queryInterfaceRequest.filter(annotationPredicate),
            association: association)
    }
}
