public struct HasManyThroughAssociation<Left: TableMapping, Middle: TableMapping, Right: TableMapping> {
    let middleJoinMappingRequest: JoinMappingRequest
    let middleRequest: QueryInterfaceRequest<Middle>
    let rightJoinMappingRequest: JoinMappingRequest
    let rightRequest: QueryInterfaceRequest<Right>
    
    func middleMapping(_ db: Database) throws -> [(left: String, right: String)] {
        let mappings = try middleJoinMappingRequest.fetchAll(db)
        switch mappings.count {
        case 0:
            fatalError("Could not infer foreign key from \(Middle.databaseTableName) to \(Left.databaseTableName)")
        case 1:
            return mappings[0].map { (left: $0.destination, right: $0.origin) }
        default:
            fatalError("Ambiguous foreign key from \(Middle.databaseTableName) to \(Left.databaseTableName)")
        }
    }
    
    func rightMapping(_ db: Database) throws -> [(left: String, right: String)] {
        let mappings = try rightJoinMappingRequest.fetchAll(db)
        switch mappings.count {
        case 0:
            fatalError("Could not infer foreign key from \(Right.databaseTableName) to \(Middle.databaseTableName)")
        case 1:
            return mappings[0].map { (left: $0.destination, right: $0.origin) }
        default:
            fatalError("Ambiguous foreign key from \(Right.databaseTableName) to \(Middle.databaseTableName)")
        }
    }
}

extension HasManyThroughAssociation : RightRequestDerivable {
    typealias RightRowDecoder = Right
    
    func mapRightRequest(_ transform: (QueryInterfaceRequest<Right>) -> QueryInterfaceRequest<Right>) -> HasManyThroughAssociation<Left, Middle, Right> {
        return HasManyThroughAssociation(
            middleJoinMappingRequest: middleJoinMappingRequest,
            middleRequest: middleRequest,
            rightJoinMappingRequest: rightJoinMappingRequest,
            rightRequest: transform(self.rightRequest))
    }
}

extension TableMapping {
    public static func hasMany<Middle, Right>(_ right: HasManyAssociation<Middle, Right>, through middle: HasManyAssociation<Self, Middle>) -> HasManyThroughAssociation<Self, Middle, Right> where Middle: TableMapping, Right: TableMapping {
        return HasManyThroughAssociation(
            middleJoinMappingRequest: middle.joinMappingRequest,
            middleRequest: middle.rightRequest,
            rightJoinMappingRequest: right.joinMappingRequest,
            rightRequest: right.rightRequest)
    }
    
    public static func hasMany<Middle, Right>(_ right: HasOneAssociation<Middle, Right>, through middle: HasManyAssociation<Self, Middle>) -> HasManyThroughAssociation<Self, Middle, Right> where Middle: TableMapping, Right: TableMapping {
        return HasManyThroughAssociation(
            middleJoinMappingRequest: middle.joinMappingRequest,
            middleRequest: middle.rightRequest,
            rightJoinMappingRequest: right.joinMappingRequest,
            rightRequest: right.rightRequest)
    }
    
    public static func hasMany<Middle, Right>(_ right: HasManyAssociation<Middle, Right>, through middle: HasOneAssociation<Self, Middle>) -> HasManyThroughAssociation<Self, Middle, Right> where Middle: TableMapping, Right: TableMapping {
        return HasManyThroughAssociation(
            middleJoinMappingRequest: middle.joinMappingRequest,
            middleRequest: middle.rightRequest,
            rightJoinMappingRequest: right.joinMappingRequest,
            rightRequest: right.rightRequest)
    }
}
