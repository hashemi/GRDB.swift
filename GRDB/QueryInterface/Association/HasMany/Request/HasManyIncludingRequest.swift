public struct HasManyIncludingRequest<Left, Right>
    where
    Left: RequestDerivable, // TODO: Remove once SE-0143 is implemented
    Left: TypedRequest,
    Left.RowDecoder: TableMapping,
    Right: TableMapping
{
    var leftRequest: Left
    let association: HasManyAssociation<Left.RowDecoder, Right>
}

// Derive conditional conformance to LeftRequestDerivable once SE-0143 is implemented
extension HasManyIncludingRequest : LeftRequestDerivable {
    typealias LeftRequest = Left
    
    func mapLeftRequest(_ transform: (Left) -> (Left)) -> HasManyIncludingRequest<Left, Right> {
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
        var leftKeys: [DatabaseValue] = []
        var resultIndexes : [DatabaseValue: Int] = [:]
        
        // SELECT * FROM left...
        do {
            // Where is the left key?
            // TODO: simplify the code below. Because of adapters, it is complex to get the index of a column in a row:
            let (statement, adapter) = try leftRequest.prepare(db)
            let cursor = try Row.fetchCursor(statement, adapter: adapter)
            let layout: RowLayout = try adapter?.layoutedAdapter(from: statement).mapping ?? statement
            guard let leftKeyIndex = layout.layoutIndex(ofColumn: leftKeyColumn) else {
                fatalError("Column \(Left.RowDecoder.databaseTableName).\(leftKeyColumn) is not selected")
            }
            
            let enumeratedCursor = cursor.enumerated()
            while let (recordIndex, row) = try enumeratedCursor.next() {
                let left = Left.RowDecoder(row: row)
                let key: DatabaseValue = row.value(atIndex: leftKeyIndex)
                leftKeys.append(key)
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
            let rightQuery = association.rightRequest.filter(leftKeys.contains(Column(rightKeyColumn))).query
            
            // Where is the left key?
            // TODO: simplify the code below. Because of adapters, it is complex to get the index of a column in a row:
            let (statement, adapter) = try rightQuery.prepare(db)
            let cursor = try Row.fetchCursor(statement, adapter: adapter)
            let layout: RowLayout = try adapter?.layoutedAdapter(from: statement).mapping ?? statement
            guard let leftKeyIndex = layout.layoutIndex(ofColumn: rightKeyColumn) else {
                fatalError("not implemented: support for non-selected \(Right.databaseTableName).\(rightKeyColumn) column")
            }
            
            while let row = try cursor.next() {
                let right = Right(row: row)
                let leftKey: DatabaseValue = row.value(atIndex: leftKeyIndex)
                let index = resultIndexes[leftKey]! // index has been recorded during leftRequest iteration
                result[index].right.append(right)
            }
        }
        
        return result
    }
}

extension TypedRequest where Self: RequestDerivable, RowDecoder: TableMapping {
    public func including<Right>(_ association: HasManyAssociation<RowDecoder, Right>) -> HasManyIncludingRequest<Self, Right> where Right: TableMapping {
        return HasManyIncludingRequest(leftRequest: self, association: association)
    }
}

extension TableMapping {
    public static func including<Right>(_ association: HasManyAssociation<Self, Right>) -> HasManyIncludingRequest<QueryInterfaceRequest<Self>, Right> where Right: TableMapping {
        return all().including(association)
    }
}

extension HasManyIncludingRequest where Left: QueryInterfaceRequestConvertible {
    public func filter<Right2, Annotation>(_ expression: HasManyAnnotationHavingExpression<Left.RowDecoder, Right2, Annotation>) -> HasManyIncludingRequest<HasManyAnnotationHavingRequest<Left.RowDecoder, Right2, Annotation>, Right> where Right2: TableMapping {
        // Use type inference when Swift is able to do it
        return HasManyIncludingRequest<HasManyAnnotationHavingRequest<Left.RowDecoder, Right2, Annotation>, Right>(
            leftRequest: leftRequest.queryInterfaceRequest.filter(expression),
            association: association)
    }
    
    public func filter<MiddleAssociation2, RightAssociation2, Annotation>(_ expression: HasManyThroughAnnotationHavingExpression<MiddleAssociation2, RightAssociation2, Annotation>) -> HasManyIncludingRequest<HasManyThroughAnnotationHavingRequest<MiddleAssociation2, RightAssociation2, Annotation>, Right> where MiddleAssociation2.LeftAssociated == Left.RowDecoder {
        // Use type inference when Swift is able to do it
        return HasManyIncludingRequest<HasManyThroughAnnotationHavingRequest<MiddleAssociation2, RightAssociation2, Annotation>, Right>(
            leftRequest: leftRequest.queryInterfaceRequest.filter(expression),
            association: association)
    }
}
