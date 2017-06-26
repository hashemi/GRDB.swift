public struct HasOneAssociation<Left: TableMapping, Right: TableMapping> : AssociationToOne {
    public typealias LeftAssociated = Left
    public typealias RightAssociated = Right
    
    let joinMappingRequest: JoinMappingRequest
    public let rightRequest: QueryInterfaceRequest<Right>
    
    public func mapping(_ db: Database) throws -> [(left: String, right: String)] {
        return try joinMappingRequest
            .fetchMapping(db)
            .map { (left: $0.destination, right: $0.origin) }
    }
}

extension HasOneAssociation : RightRequestDerivable {
    public typealias RightRowDecoder = Right
    
    public func mapRightRequest(_ transform: (QueryInterfaceRequest<Right>) -> QueryInterfaceRequest<Right>) -> HasOneAssociation<Left, Right> {
        return HasOneAssociation(joinMappingRequest: joinMappingRequest, rightRequest: transform(self.rightRequest))
    }
}

extension TableMapping {
    public static func hasOne<Right>(_ right: Right.Type) -> HasOneAssociation<Self, Right> where Right: TableMapping {
        let joinMappingRequest = JoinMappingRequest(
            originTable: Right.databaseTableName,
            destinationTable: databaseTableName)
        return HasOneAssociation(joinMappingRequest: joinMappingRequest, rightRequest: Right.all())
    }
    
    public static func hasOne<Right>(_ right: Right.Type, from originColumns: String...) -> HasOneAssociation<Self, Right> where Right: TableMapping {
        let joinMappingRequest = JoinMappingRequest(
            originTable: Right.databaseTableName,
            destinationTable: databaseTableName,
            originColumns: originColumns)
        return HasOneAssociation(joinMappingRequest: joinMappingRequest, rightRequest: Right.all())
    }
    
    public static func hasOne<Right>(_ right: Right.Type, from originColumns: [String], to destinationColumns: [String]) -> HasOneAssociation<Self, Right> where Right: TableMapping {
        let joinMappingRequest = JoinMappingRequest(
            originTable: Right.databaseTableName,
            destinationTable: databaseTableName,
            originColumns: originColumns,
            destinationColumns: destinationColumns)
        return HasOneAssociation(joinMappingRequest: joinMappingRequest, rightRequest: Right.all())
    }
}
