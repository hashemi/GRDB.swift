public struct HasManyIncludingRequest<Left: TableMapping, Right: TableMapping> {
    var leftRequest: QueryInterfaceRequest<Left>
    let association: HasManyAssociation<Left, Right>
}

extension HasManyIncludingRequest : LeftRequestDerivable {
    typealias LeftRowDecoder = Left
    
    func mapLeftRequest(_ transform: (QueryInterfaceRequest<Left>) -> (QueryInterfaceRequest<Left>)) -> HasManyIncludingRequest<Left, Right> {
        return HasManyIncludingRequest(leftRequest: transform(leftRequest), association: association)
    }
}

extension HasManyIncludingRequest where Left: RowConvertible, Right: RowConvertible {
    public func fetchAll(_ db: Database) throws -> [(left: Left, right: [Right])] {
        let mapping = try association.mapping(db)
        var result: [(left: Left, right: [Right])] = []
        var leftKeys: [RowValue] = []
        var resultIndexes : [RowValue: Int] = [:]
        
        // SELECT * FROM left...
        do {
            let cursor = try Row.fetchCursor(db, leftRequest)
            let foreignKeyIndexes = mapping.map { arrow -> Int in
                if let index = cursor.statementIndex(ofColumn: arrow.left) {
                    return index
                } else {
                    fatalError("Column \(Left.databaseTableName).\(arrow.left) is not selected")
                }
            }
            let enumeratedCursor = cursor.enumerated()
            while let (recordIndex, row) = try enumeratedCursor.next() {
                let left = Left(row: row)
                let key = RowValue(foreignKeyIndexes.map { row.value(atIndex: $0) })
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
            let leftKeyValues = leftKeys.lazy.map { $0.dbValues[0] }
            let rightColumn = mapping[0].right
            let rightRequest = association.rightRequest.filter(leftKeyValues.contains(Column(rightColumn)))
            let cursor = try Row.fetchCursor(db, rightRequest)
            let foreignKeyIndexes = mapping.map { arrow -> Int in
                if let index = cursor.statementIndex(ofColumn: arrow.right) {
                    return index
                } else {
                    fatalError("Column \(Right.databaseTableName).\(arrow.right) is not selected")
                }
            }
            while let row = try cursor.next() {
                let right = Right(row: row)
                let foreignKey = RowValue(foreignKeyIndexes.map { row.value(atIndex: $0) })
                let index = resultIndexes[foreignKey]! // index has been recorded during leftRequest iteration
                result[index].right.append(right)
            }
        }
        
        return result
    }
}

extension QueryInterfaceRequest where RowDecoder: TableMapping {
    public func including<Right>(_ association: HasManyAssociation<RowDecoder, Right>) -> HasManyIncludingRequest<RowDecoder, Right> where Right: TableMapping {
        return HasManyIncludingRequest(leftRequest: self, association: association)
    }
}

extension TableMapping {
    public static func including<Right>(_ association: HasManyAssociation<Self, Right>) -> HasManyIncludingRequest<Self, Right> where Right: TableMapping {
        return all().including(association)
    }
}
