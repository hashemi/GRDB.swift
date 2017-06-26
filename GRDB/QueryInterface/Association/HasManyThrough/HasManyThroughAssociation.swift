// Remove RightRequestDerivable conformance once https://github.com/apple/swift-evolution/blob/master/proposals/0143-conditional-conformances.md is implemented
public struct HasManyThroughAssociation<MiddleAssociation, RightAssociation>
    where
    MiddleAssociation: Association,
    RightAssociation: Association,
    RightAssociation: RightRequestDerivable,
    RightAssociation.LeftAssociated == MiddleAssociation.RightAssociated,
    RightAssociation.RightAssociated == RightAssociation.RightRowDecoder
{
    let middleAssociation: MiddleAssociation
    let rightAssociation: RightAssociation
}

// Derive conditional conformance to RightRequestDerivableonce and remove public qualifiers once https://github.com/apple/swift-evolution/blob/master/proposals/0143-conditional-conformances.md is implemented
extension HasManyThroughAssociation : RightRequestDerivable {
    public typealias RightRowDecoder = RightAssociation.RightAssociated
    
    public func mapRightRequest(_ transform: (QueryInterfaceRequest<RightRowDecoder>) -> QueryInterfaceRequest<RightRowDecoder>) -> HasManyThroughAssociation<MiddleAssociation, RightAssociation> {
        return HasManyThroughAssociation(
            middleAssociation: middleAssociation,
            rightAssociation: rightAssociation.mapRightRequest(transform))
    }
}

extension TableMapping {
    public static func hasMany<MiddleAssociation, RightAssociation>(_ rightAssociation: RightAssociation, through middleAssociation: MiddleAssociation) -> HasManyThroughAssociation<MiddleAssociation, RightAssociation> where MiddleAssociation.LeftAssociated == Self, MiddleAssociation.RightAssociated == RightAssociation.LeftAssociated {
        return HasManyThroughAssociation(
            middleAssociation: middleAssociation,
            rightAssociation: rightAssociation)
    }
}
