public struct HasManyThroughAssociation<MiddleAssociation, RightAssociation>
    where
    MiddleAssociation: Association,
    RightAssociation: RightRequestDerivable, // TODO: Remove once SE-0143 is implemented
    RightAssociation: Association,
    MiddleAssociation.RightAssociated == RightAssociation.LeftAssociated
{
    let middleAssociation: MiddleAssociation
    let rightAssociation: RightAssociation
}

// Derive conditional conformance to RightRequestDerivableonce once SE-0143 is implemented
extension HasManyThroughAssociation : RightRequestDerivable {
    public typealias RightRequest = RightAssociation.RightRequest
    
    public func mapRightRequest(_ transform: (RightRequest) -> RightRequest) -> HasManyThroughAssociation<MiddleAssociation, RightAssociation> {
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
