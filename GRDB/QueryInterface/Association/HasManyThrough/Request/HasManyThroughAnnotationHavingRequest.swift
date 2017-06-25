// Remove RightRequestDerivable conformance once https://github.com/apple/swift-evolution/blob/master/proposals/0143-conditional-conformances.md is implemented
public struct HasManyThroughAnnotationHavingRequest<MiddleAssociation: Association, RightAssociation: Association, Annotation> where MiddleAssociation.RightAssociated == RightAssociation.LeftAssociated, RightAssociation: RightRequestDerivable, RightAssociation.RightRowDecoder == RightAssociation.RightAssociated {
    var leftRequest: QueryInterfaceRequest<MiddleAssociation.LeftAssociated>
    let annotationHavingExpression: HasManyThroughAnnotationHavingExpression<MiddleAssociation, RightAssociation, Annotation>
}

extension HasManyThroughAnnotationHavingRequest : LeftRequestDerivable {
    typealias LeftRowDecoder = MiddleAssociation.LeftAssociated
    
    func mapLeftRequest(_ transform: (QueryInterfaceRequest<MiddleAssociation.LeftAssociated>) -> (QueryInterfaceRequest<MiddleAssociation.LeftAssociated>)) -> HasManyThroughAnnotationHavingRequest<MiddleAssociation, RightAssociation, Annotation> {
        return HasManyThroughAnnotationHavingRequest(leftRequest: transform(leftRequest), annotationHavingExpression: annotationHavingExpression)
    }
}

extension HasManyThroughAnnotationHavingRequest : TypedRequest {
    public typealias RowDecoder = MiddleAssociation.LeftAssociated
    
    public func prepare(_ db: Database) throws -> (SelectStatement, RowAdapter?) {
        fatalError("Not implemented")
    }
}

extension QueryInterfaceRequest where RowDecoder: TableMapping {
    public func filter<MiddleAssociation, RightAssociation, Annotation>(_ expression: HasManyThroughAnnotationHavingExpression<MiddleAssociation, RightAssociation, Annotation>) -> HasManyThroughAnnotationHavingRequest<MiddleAssociation, RightAssociation, Annotation> where MiddleAssociation.LeftAssociated == RowDecoder {
        return HasManyThroughAnnotationHavingRequest(leftRequest: self, annotationHavingExpression: expression)
    }
}

extension TableMapping {
    public static func filter<MiddleAssociation, RightAssociation, Annotation>(_ expression: HasManyThroughAnnotationHavingExpression<MiddleAssociation, RightAssociation, Annotation>) -> HasManyThroughAnnotationHavingRequest<MiddleAssociation, RightAssociation, Annotation> where MiddleAssociation.LeftAssociated == Self {
        return all().filter(expression)
    }
}
