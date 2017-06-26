// Remove RightRequestDerivable conformance once https://github.com/apple/swift-evolution/blob/master/proposals/0143-conditional-conformances.md is implemented
public struct HasManyThroughIncludingRequest<MiddleAssociation, RightAssociation>
    where
    MiddleAssociation: Association,
    RightAssociation: Association,
    RightAssociation: RightRequestDerivable,
    RightAssociation.LeftAssociated == MiddleAssociation.RightAssociated,
    RightAssociation.RightAssociated == RightAssociation.RightRowDecoder
{
    var leftRequest: QueryInterfaceRequest<MiddleAssociation.LeftAssociated>
    let association: HasManyThroughAssociation<MiddleAssociation, RightAssociation>
}

extension HasManyThroughIncludingRequest : LeftRequestDerivable {
    typealias LeftRowDecoder = MiddleAssociation.LeftAssociated
    
    func mapLeftRequest(_ transform: (QueryInterfaceRequest<MiddleAssociation.LeftAssociated>) -> (QueryInterfaceRequest<MiddleAssociation.LeftAssociated>)) -> HasManyThroughIncludingRequest<MiddleAssociation, RightAssociation> {
        return HasManyThroughIncludingRequest(leftRequest: transform(leftRequest), association: association)
    }
}

extension HasManyThroughIncludingRequest where MiddleAssociation.LeftAssociated: RowConvertible, RightAssociation.RightAssociated : RowConvertible {
    public func fetchAll(_ db: Database) throws -> [(left: MiddleAssociation.LeftAssociated, right: [RightAssociation.RightAssociated])] {
        fatalError("Not implemented")
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
