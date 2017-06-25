public struct BelongsToAssociation<Left: TableMapping, Right: TableMapping> {
    let joinMappingRequest: JoinMappingRequest
    let rightRequest: QueryInterfaceRequest<Right>
    
    func mapping(_ db: Database) throws -> [(left: String, right: String)] {
        let mappings = try joinMappingRequest.fetchAll(db)
        switch mappings.count {
        case 0:
            fatalError("Could not infer foreign key from \(Left.databaseTableName) to \(Right.databaseTableName)")
        case 1:
            return mappings[0].map { (left: $0.origin, right: $0.destination) }
        default:
            fatalError("Ambiguous foreign key from \(Left.databaseTableName) to \(Right.databaseTableName)")
        }
    }
}

extension BelongsToAssociation : RightRequestDerivable {
    typealias RightRowDecoder = Right
    func mapRightRequest(_ transform: (QueryInterfaceRequest<Right>) -> QueryInterfaceRequest<Right>) -> BelongsToAssociation<Left, Right> {
        return BelongsToAssociation(joinMappingRequest: joinMappingRequest, rightRequest: transform(self.rightRequest))
    }
}

extension TableMapping {
    public static func belongsTo<Right>(_ right: Right.Type) -> BelongsToAssociation<Self, Right> where Right: TableMapping {
        let joinMappingRequest = JoinMappingRequest(
            originTable: databaseTableName,
            destinationTable: Right.databaseTableName)
        return BelongsToAssociation(joinMappingRequest: joinMappingRequest, rightRequest: Right.all())
    }
    
    public static func belongsTo<Right>(_ right: Right.Type, from originColumns: String...) -> BelongsToAssociation<Self, Right> where Right: TableMapping {
        let joinMappingRequest = JoinMappingRequest(
            originTable: databaseTableName,
            destinationTable: Right.databaseTableName,
            originColumns: originColumns)
        return BelongsToAssociation(joinMappingRequest: joinMappingRequest, rightRequest: Right.all())
    }
    
    public static func belongsTo<Right>(_ right: Right.Type, from originColumns: [String], to destinationColumns: [String]) -> BelongsToAssociation<Self, Right> where Right: TableMapping {
        let joinMappingRequest = JoinMappingRequest(
            originTable: databaseTableName,
            destinationTable: Right.databaseTableName,
            originColumns: originColumns,
            destinationColumns: destinationColumns)
        return BelongsToAssociation(joinMappingRequest: joinMappingRequest, rightRequest: Right.all())
    }
}
