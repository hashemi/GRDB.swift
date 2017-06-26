public struct HasManyThroughAnnotationHavingExpression<MiddleAssociation, RightAssociation, Annotation>
    where
    MiddleAssociation: Association,
    RightAssociation: Association,
    RightAssociation: RightRequestDerivable,
    RightAssociation.LeftAssociated == MiddleAssociation.RightAssociated,
    RightAssociation.RightAssociated == RightAssociation.RightRowDecoder
{    
    let annotation: HasManyThroughAnnotation<MiddleAssociation, RightAssociation, Annotation>
    let havingExpression: (SQLExpression) -> SQLExpression
    
    func map(_ transform: @escaping (SQLExpression) -> SQLExpression) -> HasManyThroughAnnotationHavingExpression {
        return HasManyThroughAnnotationHavingExpression(
            annotation: annotation,
            havingExpression: { transform(self.havingExpression($0)) })
    }
}

extension HasManyThroughAnnotation {
    func havingExpression(_ havingExpression: @escaping (SQLExpression) -> SQLExpression) -> HasManyThroughAnnotationHavingExpression<MiddleAssociation, RightAssociation, Annotation> {
        return HasManyThroughAnnotationHavingExpression(
            annotation: self,
            havingExpression: havingExpression)
    }
}

public prefix func ! <MiddleAssociation, RightAssociation, Annotation>(value: HasManyThroughAnnotationHavingExpression<MiddleAssociation, RightAssociation, Annotation>) -> HasManyThroughAnnotationHavingExpression<MiddleAssociation, RightAssociation, Annotation> {
    return value.map { !$0 }
}

public func == <MiddleAssociation, RightAssociation, Annotation>(lhs: HasManyThroughAnnotation<MiddleAssociation, RightAssociation, Annotation>, rhs: Annotation?) -> HasManyThroughAnnotationHavingExpression<MiddleAssociation, RightAssociation, Annotation> where Annotation: SQLExpressible {
    return lhs.havingExpression { $0 == rhs }
}

public func != <MiddleAssociation, RightAssociation, Annotation>(lhs: HasManyThroughAnnotation<MiddleAssociation, RightAssociation, Annotation>, rhs: Annotation?) -> HasManyThroughAnnotationHavingExpression<MiddleAssociation, RightAssociation, Annotation> where Annotation: SQLExpressible {
    return lhs.havingExpression { $0 != rhs }
}

public func === <MiddleAssociation, RightAssociation, Annotation>(lhs: HasManyThroughAnnotation<MiddleAssociation, RightAssociation, Annotation>, rhs: Annotation?) -> HasManyThroughAnnotationHavingExpression<MiddleAssociation, RightAssociation, Annotation> where Annotation: SQLExpressible {
    return lhs.havingExpression { $0 === rhs }
}

public func !== <MiddleAssociation, RightAssociation, Annotation>(lhs: HasManyThroughAnnotation<MiddleAssociation, RightAssociation, Annotation>, rhs: Annotation?) -> HasManyThroughAnnotationHavingExpression<MiddleAssociation, RightAssociation, Annotation> where Annotation: SQLExpressible {
    return lhs.havingExpression { $0 !== rhs }
}

public func < <MiddleAssociation, RightAssociation, Annotation>(lhs: HasManyThroughAnnotation<MiddleAssociation, RightAssociation, Annotation>, rhs: Annotation) -> HasManyThroughAnnotationHavingExpression<MiddleAssociation, RightAssociation, Annotation> where Annotation: SQLExpressible {
    return lhs.havingExpression { $0 < rhs }
}

public func <= <MiddleAssociation, RightAssociation, Annotation>(lhs: HasManyThroughAnnotation<MiddleAssociation, RightAssociation, Annotation>, rhs: Annotation) -> HasManyThroughAnnotationHavingExpression<MiddleAssociation, RightAssociation, Annotation> where Annotation: SQLExpressible {
    return lhs.havingExpression { $0 <= rhs }
}

public func > <MiddleAssociation, RightAssociation, Annotation>(lhs: HasManyThroughAnnotation<MiddleAssociation, RightAssociation, Annotation>, rhs: Annotation) -> HasManyThroughAnnotationHavingExpression<MiddleAssociation, RightAssociation, Annotation> where Annotation: SQLExpressible {
    return lhs.havingExpression { $0 > rhs }
}

public func >= <MiddleAssociation, RightAssociation, Annotation>(lhs: HasManyThroughAnnotation<MiddleAssociation, RightAssociation, Annotation>, rhs: Annotation) -> HasManyThroughAnnotationHavingExpression<MiddleAssociation, RightAssociation, Annotation> where Annotation: SQLExpressible {
    return lhs.havingExpression { $0 >= rhs }
}
