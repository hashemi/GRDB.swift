public struct HasManyAssociation<Left: TableMapping, Right: TableMapping> : Association {
    public typealias LeftAssociated = Left
    public typealias RightAssociated = Right
    
    let joinMappingRequest: JoinMappingRequest
    public let rightRequest: QueryInterfaceRequest<Right>
    
    public func mapping(_ db: Database) throws -> [(left: String, right: String)] {
        let mappings = try joinMappingRequest.fetchAll(db)
        switch mappings.count {
        case 0:
            fatalError("Could not infer foreign key from \(Right.databaseTableName) to \(Left.databaseTableName)")
        case 1:
            return mappings[0].map { (left: $0.destination, right: $0.origin) }
        default:
            fatalError("Ambiguous foreign key from \(Right.databaseTableName) to \(Left.databaseTableName)")
        }
    }
}

extension HasManyAssociation : RightRequestDerivable {
    public typealias RightRowDecoder = Right
    
    public func mapRightRequest(_ transform: (QueryInterfaceRequest<Right>) -> QueryInterfaceRequest<Right>) -> HasManyAssociation<Left, Right> {
        return HasManyAssociation(joinMappingRequest: joinMappingRequest, rightRequest: transform(self.rightRequest))
    }
}

extension TableMapping {
    public static func hasMany<Right>(_ right: Right.Type) -> HasManyAssociation<Self, Right> where Right: TableMapping {
        let joinMappingRequest = JoinMappingRequest(
            originTable: Right.databaseTableName,
            destinationTable: databaseTableName)
        return HasManyAssociation(joinMappingRequest: joinMappingRequest, rightRequest: Right.all())
    }
    
    public static func hasMany<Right>(_ right: Right.Type, from originColumns: String...) -> HasManyAssociation<Self, Right> where Right: TableMapping {
        let joinMappingRequest = JoinMappingRequest(
            originTable: Right.databaseTableName,
            destinationTable: databaseTableName,
            originColumns: originColumns)
        return HasManyAssociation(joinMappingRequest: joinMappingRequest, rightRequest: Right.all())
    }
    
    public static func hasMany<Right>(_ right: Right.Type, from originColumns: [String], to destinationColumns: [String]) -> HasManyAssociation<Self, Right> where Right: TableMapping {
        let joinMappingRequest = JoinMappingRequest(
            originTable: Right.databaseTableName,
            destinationTable: databaseTableName,
            originColumns: originColumns,
            destinationColumns: destinationColumns)
        return HasManyAssociation(joinMappingRequest: joinMappingRequest, rightRequest: Right.all())
    }
}
