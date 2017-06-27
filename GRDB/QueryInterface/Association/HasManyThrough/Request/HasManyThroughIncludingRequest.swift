// Remove RightRequestDerivable conformance once https://github.com/apple/swift-evolution/blob/master/proposals/0143-conditional-conformances.md is implemented
public struct HasManyThroughIncludingRequest<MiddleAssociation, RightAssociation>
    where
    MiddleAssociation: Association,
    RightAssociation: Association,
    RightAssociation: RightRequestDerivable,
    RightAssociation.LeftAssociated == MiddleAssociation.RightAssociated
{
    typealias LeftRequest = QueryInterfaceRequest<MiddleAssociation.LeftAssociated>
    
    var leftRequest: LeftRequest
    let association: HasManyThroughAssociation<MiddleAssociation, RightAssociation>
}

extension HasManyThroughIncludingRequest : LeftRequestDerivable {
    func mapLeftRequest(_ transform: (LeftRequest) -> (LeftRequest)) -> HasManyThroughIncludingRequest<MiddleAssociation, RightAssociation> {
        return HasManyThroughIncludingRequest(
            leftRequest: transform(leftRequest),
            association: association)
    }
}

extension HasManyThroughIncludingRequest where MiddleAssociation.LeftAssociated: RowConvertible, RightAssociation.RightAssociated : RowConvertible {
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

extension QueryInterfaceRequest where RowDecoder: TableMapping {
    public func including<MiddleAssociation, RightAssociation>(_ association: HasManyThroughAssociation<MiddleAssociation, RightAssociation>) -> HasManyThroughIncludingRequest<MiddleAssociation, RightAssociation> where MiddleAssociation.LeftAssociated == RowDecoder {
        return HasManyThroughIncludingRequest(leftRequest: self, association: association)
    }
}

extension TableMapping {
    public static func including<MiddleAssociation, RightAssociation>(_ association: HasManyThroughAssociation<MiddleAssociation, RightAssociation>) -> HasManyThroughIncludingRequest<MiddleAssociation, RightAssociation> where MiddleAssociation.LeftAssociated == Self {
        return all().including(association)
    }
}
