public struct HasOneThroughAssociation<MiddleAssociation, RightAssociation> where
    MiddleAssociation: AssociationToOne,
    RightAssociation: RightRequestDerivable, // TODO: Remove once SE-0143 is implemented
    RightAssociation: AssociationToOne,
    MiddleAssociation.RightAssociated == RightAssociation.LeftAssociated
{
    let middleAssociation: MiddleAssociation
    let rightAssociation: RightAssociation
}

// Derive conditional conformance to RightRequestDerivableonce once SE-0143 is implemented
extension HasOneThroughAssociation : RightRequestDerivable {
    public typealias RightRequest = RightAssociation.RightRequest
    
    public func mapRightRequest(_ transform: (RightRequest) -> RightRequest) -> HasOneThroughAssociation<MiddleAssociation, RightAssociation> {
        return HasOneThroughAssociation(
            middleAssociation: middleAssociation,
            rightAssociation: rightAssociation.mapRightRequest(transform))
    }
}

extension TableMapping {
    public static func hasOne<MiddleAssociation, RightAssociation>(_ rightAssociation: RightAssociation, through middleAssociation: MiddleAssociation)
        -> HasOneThroughAssociation<MiddleAssociation, RightAssociation>
        where
        MiddleAssociation.LeftAssociated == Self,
        MiddleAssociation.RightAssociated == RightAssociation.LeftAssociated
    {
        return HasOneThroughAssociation(
            middleAssociation: middleAssociation,
            rightAssociation: rightAssociation)
    }
}
