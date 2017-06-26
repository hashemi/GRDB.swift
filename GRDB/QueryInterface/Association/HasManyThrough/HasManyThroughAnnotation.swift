// Remove RightRequestDerivable conformance once https://github.com/apple/swift-evolution/blob/master/proposals/0143-conditional-conformances.md is implemented
public struct HasManyThroughAnnotation<MiddleAssociation, RightAssociation, Annotation>
    where
    MiddleAssociation: Association,
    RightAssociation: Association,
    RightAssociation: RightRequestDerivable,
    RightAssociation.LeftAssociated == MiddleAssociation.RightAssociated,
    RightAssociation.RightAssociated == RightAssociation.RightRowDecoder
{
    let association: HasManyThroughAssociation<MiddleAssociation, RightAssociation>
    let expression: (Database) throws -> SQLExpression
}

extension HasManyThroughAssociation {
    public var count: HasManyThroughAnnotation<MiddleAssociation, RightAssociation, Int> {
        // SELECT left.*, COUNT(right.*) FROM left LEFT JOIN middle LEFT JOIN right ...
        guard let rightTable = rightAssociation.rightRequest.query.source?.tableName else {
            fatalError("Can't count tableless query")
        }
        return HasManyThroughAnnotation(
            association: self,
            expression: { db in
                if let primaryKey = try db.primaryKey(rightTable) {
                    guard primaryKey.columns.count == 1 else {
                        fatalError("Not implemented: count table with compound primary key")
                    }
                    return SQLExpressionCount(Column(primaryKey.columns[0]))
                } else {
                    return SQLExpressionCount(Column.rowID)
                }
        })
    }
    
    public var isEmpty: HasManyThroughAnnotationHavingExpression<MiddleAssociation, RightAssociation, Int> {
        return count == 0
    }
}
