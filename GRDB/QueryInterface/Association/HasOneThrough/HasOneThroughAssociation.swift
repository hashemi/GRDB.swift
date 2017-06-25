// Remove RightRequestDerivable conformance once https://github.com/apple/swift-evolution/blob/master/proposals/0143-conditional-conformances.md is implemented
public struct HasOneThroughAssociation<MiddleAssociation: AssociationToOne, RightAssociation: AssociationToOne> where MiddleAssociation.RightAssociated == RightAssociation.LeftAssociated, RightAssociation: RightRequestDerivable, RightAssociation.RightRowDecoder == RightAssociation.RightAssociated {
    let middleAssociation: MiddleAssociation
    let rightAssociation: RightAssociation
}

// Derive conditional conformance to RightRequestDerivableonce and remove public qualifiers once https://github.com/apple/swift-evolution/blob/master/proposals/0143-conditional-conformances.md is implemented
extension HasOneThroughAssociation : RightRequestDerivable {
    public typealias RightRowDecoder = RightAssociation.RightAssociated
    
    public func mapRightRequest(_ transform: (QueryInterfaceRequest<RightRowDecoder>) -> QueryInterfaceRequest<RightRowDecoder>) -> HasOneThroughAssociation<MiddleAssociation, RightAssociation> {
        return HasOneThroughAssociation(
            middleAssociation: middleAssociation,
            rightAssociation: rightAssociation.mapRightRequest(transform))
    }
}

extension TableMapping {
    public static func hasOne<MiddleAssociation, RightAssociation>(_ rightAssociation: RightAssociation, through middleAssociation: MiddleAssociation) -> HasOneThroughAssociation<MiddleAssociation, RightAssociation> where MiddleAssociation.LeftAssociated == Self, MiddleAssociation.RightAssociated == RightAssociation.LeftAssociated {
        return HasOneThroughAssociation(
            middleAssociation: middleAssociation,
            rightAssociation: rightAssociation)
    }
}
