public struct HasManyThroughAnnotation<MiddleAssociation: Association, RightAssociation: Association, Annotation> where MiddleAssociation.RightAssociated == RightAssociation.LeftAssociated, RightAssociation: RightRequestDerivable, RightAssociation.RightRowDecoder == RightAssociation.RightAssociated {
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