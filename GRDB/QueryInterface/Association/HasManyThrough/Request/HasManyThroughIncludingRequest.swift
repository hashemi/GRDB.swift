public struct HasManyThroughIncludingRequest<Left, MiddleAssociation, RightAssociation>
    where
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
    public func fetchAll(_ db: Database) throws -> [(left: MiddleAssociation.LeftAssociated, right: [RightAssociation.RightAssociated])] {
        let middleMapping = try association.middleAssociation.mapping(db)
        guard middleMapping.count == 1 else {
            fatalError("not implemented: support for compound foreign keys")
        }
        let leftKeyColumn = middleMapping[0].left
        let middleKeyColumn = middleMapping[0].right
        
        var result: [(left: MiddleAssociation.LeftAssociated, right: [RightAssociation.RightAssociated])] = []
        var leftKeys: [DatabaseValue] = []
        var resultIndexes : [DatabaseValue: Int] = [:]
        
        // SELECT * FROM left...
        do {
            let cursor = try Row.fetchCursor(db, leftRequest)
            guard let leftKeyIndex = cursor.statementIndex(ofColumn: leftKeyColumn) else {
                fatalError("Column \(MiddleAssociation.LeftAssociated.databaseTableName).\(leftKeyColumn) is not selected")
            }
            let enumeratedCursor = cursor.enumerated()
            while let (recordIndex, row) = try enumeratedCursor.next() {
                let left = MiddleAssociation.LeftAssociated(row: row)
                let key: DatabaseValue = row.value(atIndex: leftKeyIndex)
                leftKeys.append(key)
                resultIndexes[key] = recordIndex
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
            .filter(leftKeys.contains(Column(middleKeyColumn)))
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
                // Left columns start at index 0
                "left": SuffixRowAdapter(fromIndex: 0),
                // Right columns start after left columns
                "right": SuffixRowAdapter(fromIndex: 1)]))

        let cursor = try Row.fetchCursor(db, joinedRequest)

        while let row = try cursor.next() {
            let right = RightAssociation.RightAssociated(row: row.scoped(on: "right")!)
            let leftKey: DatabaseValue = row.scoped(on: "left")!.value(atIndex: 0)
            let index = resultIndexes[leftKey]! // index has been recorded during leftRequest iteration
            result[index].right.append(right)
        }
        
        return result
    }
}

extension TypedRequest where Self: RequestDerivable, RowDecoder: TableMapping {
    public func including<MiddleAssociation, RightAssociation>(_ association: HasManyThroughAssociation<MiddleAssociation, RightAssociation>) -> HasManyThroughIncludingRequest<Self, MiddleAssociation, RightAssociation> where MiddleAssociation.LeftAssociated == RowDecoder {
        return HasManyThroughIncludingRequest(leftRequest: self, association: association)
    }
}

extension TableMapping {
    public static func including<MiddleAssociation, RightAssociation>(_ association: HasManyThroughAssociation<MiddleAssociation, RightAssociation>) -> HasManyThroughIncludingRequest<QueryInterfaceRequest<Self>, MiddleAssociation, RightAssociation> where MiddleAssociation.LeftAssociated == Self {
        return all().including(association)
    }
}

extension HasManyThroughIncludingRequest where Left: QueryInterfaceRequestConvertible {
    public func filter<Right2, Annotation>(_ expression: HasManyAnnotationHavingExpression<Left.RowDecoder, Right2, Annotation>) -> HasManyThroughIncludingRequest<HasManyAnnotationHavingRequest<Left.RowDecoder, Right2, Annotation>, MiddleAssociation, RightAssociation> where Right2: TableMapping {
        // Use type inference when Swift is able to do it
        return HasManyThroughIncludingRequest<HasManyAnnotationHavingRequest<Left.RowDecoder, Right2, Annotation>, MiddleAssociation, RightAssociation>(
            leftRequest: leftRequest.queryInterfaceRequest.filter(expression),
            association: association)
    }
    
    public func filter<MiddleAssociation2, RightAssociation2, Annotation>(_ expression: HasManyThroughAnnotationHavingExpression<MiddleAssociation2, RightAssociation2, Annotation>) -> HasManyThroughIncludingRequest<HasManyThroughAnnotationHavingRequest<MiddleAssociation2, RightAssociation2, Annotation>, MiddleAssociation, RightAssociation> where Left.RowDecoder == MiddleAssociation2.LeftAssociated {
        // Use type inference when Swift is able to do it
        return HasManyThroughIncludingRequest<HasManyThroughAnnotationHavingRequest<MiddleAssociation2, RightAssociation2, Annotation>, MiddleAssociation, RightAssociation>(
            leftRequest: leftRequest.queryInterfaceRequest.filter(expression),
            association: association)
    }
}
