public struct HasManyThroughAssociation<MiddleAssociation: Association, RightAssociation: Association> where MiddleAssociation.RightAssociated == RightAssociation.LeftAssociated {
    let middleAssociation: MiddleAssociation
    let rightAssociation: RightAssociation
}

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
