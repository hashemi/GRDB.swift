public struct HasManyAnnotationHavingExpression<Left, Right, Annotation>
    where
    Left: TableMapping,
    Right: TableMapping
{
    let annotation: HasManyAnnotation<Left, Right, Annotation>
    let havingExpression: (SQLExpression) -> SQLExpression
    
    func map(_ transform: @escaping (SQLExpression) -> SQLExpression) -> HasManyAnnotationHavingExpression {
        return HasManyAnnotationHavingExpression(
            annotation: annotation,
            havingExpression: { transform(self.havingExpression($0)) })
    }
}

extension HasManyAnnotation {
    func having(_ havingExpression: @escaping (SQLExpression) -> SQLExpression) -> HasManyAnnotationHavingExpression<Left, Right, Annotation> {
        return HasManyAnnotationHavingExpression(
            annotation: self,
            havingExpression: havingExpression)
    }
}

public prefix func ! <Left, Right, Annotation>(value: HasManyAnnotationHavingExpression<Left, Right, Annotation>) -> HasManyAnnotationHavingExpression<Left, Right, Annotation> {
    return value.map { !$0 }
}

public func == <Left, Right, Annotation>(lhs: HasManyAnnotation<Left, Right, Annotation>, rhs: Annotation?) -> HasManyAnnotationHavingExpression<Left, Right, Annotation> where Left: TableMapping, Right: TableMapping, Annotation: SQLExpressible {
    return lhs.having { $0 == rhs }
}

public func != <Left, Right, Annotation>(lhs: HasManyAnnotation<Left, Right, Annotation>, rhs: Annotation?) -> HasManyAnnotationHavingExpression<Left, Right, Annotation> where Left: TableMapping, Right: TableMapping, Annotation: SQLExpressible {
    return lhs.having { $0 != rhs }
}

public func === <Left, Right, Annotation>(lhs: HasManyAnnotation<Left, Right, Annotation>, rhs: Annotation?) -> HasManyAnnotationHavingExpression<Left, Right, Annotation> where Left: TableMapping, Right: TableMapping, Annotation: SQLExpressible {
    return lhs.having { $0 === rhs }
}

public func !== <Left, Right, Annotation>(lhs: HasManyAnnotation<Left, Right, Annotation>, rhs: Annotation?) -> HasManyAnnotationHavingExpression<Left, Right, Annotation> where Left: TableMapping, Right: TableMapping, Annotation: SQLExpressible {
    return lhs.having { $0 !== rhs }
}

public func < <Left, Right, Annotation>(lhs: HasManyAnnotation<Left, Right, Annotation>, rhs: Annotation) -> HasManyAnnotationHavingExpression<Left, Right, Annotation> where Left: TableMapping, Right: TableMapping, Annotation: SQLExpressible {
    return lhs.having { $0 < rhs }
}

public func <= <Left, Right, Annotation>(lhs: HasManyAnnotation<Left, Right, Annotation>, rhs: Annotation) -> HasManyAnnotationHavingExpression<Left, Right, Annotation> where Left: TableMapping, Right: TableMapping, Annotation: SQLExpressible {
    return lhs.having { $0 <= rhs }
}

public func > <Left, Right, Annotation>(lhs: HasManyAnnotation<Left, Right, Annotation>, rhs: Annotation) -> HasManyAnnotationHavingExpression<Left, Right, Annotation> where Left: TableMapping, Right: TableMapping, Annotation: SQLExpressible {
    return lhs.having { $0 > rhs }
}

public func >= <Left, Right, Annotation>(lhs: HasManyAnnotation<Left, Right, Annotation>, rhs: Annotation) -> HasManyAnnotationHavingExpression<Left, Right, Annotation> where Left: TableMapping, Right: TableMapping, Annotation: SQLExpressible {
    return lhs.having { $0 >= rhs }
}
