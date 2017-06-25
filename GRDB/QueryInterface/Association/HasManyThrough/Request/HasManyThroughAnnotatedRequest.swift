// Remove RightRequestDerivable conformance once https://github.com/apple/swift-evolution/blob/master/proposals/0143-conditional-conformances.md is implemented
public struct HasManyThroughAnnotatedRequest<MiddleAssociation: Association, RightAssociation: Association, Annotation> where MiddleAssociation.RightAssociated == RightAssociation.LeftAssociated, RightAssociation: RightRequestDerivable, RightAssociation.RightRowDecoder == RightAssociation.RightAssociated {
    var leftRequest: QueryInterfaceRequest<MiddleAssociation.LeftAssociated>
    let annotation: HasManyThroughAnnotation<MiddleAssociation, RightAssociation, Annotation>
}

extension HasManyThroughAnnotatedRequest : LeftRequestDerivable {
    typealias LeftRowDecoder = MiddleAssociation.LeftAssociated
    
    func mapLeftRequest(_ transform: (QueryInterfaceRequest<MiddleAssociation.LeftAssociated>) -> (QueryInterfaceRequest<MiddleAssociation.LeftAssociated>)) -> HasManyThroughAnnotatedRequest<MiddleAssociation, RightAssociation, Annotation> {
        return HasManyThroughAnnotatedRequest(leftRequest: transform(leftRequest), annotation: annotation)
    }
}

extension HasManyThroughAnnotatedRequest : TypedRequest {
    public typealias RowDecoder = JoinedPair<MiddleAssociation.LeftAssociated, Annotation>
    
    public func prepare(_ db: Database) throws -> (SelectStatement, RowAdapter?) {
        fatalError("not implemented")
    }
}

extension QueryInterfaceRequest where RowDecoder: TableMapping {
    public func annotated<MiddleAssociation, RightAssociation, Annotation>(with annotation: HasManyThroughAnnotation<MiddleAssociation, RightAssociation, Annotation>) -> HasManyThroughAnnotatedRequest<MiddleAssociation, RightAssociation, Annotation> where MiddleAssociation.LeftAssociated == RowDecoder {
        return HasManyThroughAnnotatedRequest(leftRequest: self, annotation: annotation)
    }
}

extension TableMapping {
    public static func annotated<MiddleAssociation, RightAssociation, Annotation>(with annotation: HasManyThroughAnnotation<MiddleAssociation, RightAssociation, Annotation>) -> HasManyThroughAnnotatedRequest<MiddleAssociation, RightAssociation, Annotation> where MiddleAssociation.LeftAssociated == Self {
        return all().annotated(with: annotation)
    }
}
