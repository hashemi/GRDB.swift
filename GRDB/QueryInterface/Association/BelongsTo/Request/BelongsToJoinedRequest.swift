public struct BelongsToJoinedRequest<Left: TableMapping, Right: TableMapping> {
    var leftRequest: QueryInterfaceRequest<Left>
    let association: BelongsToAssociation<Left, Right>
}

extension BelongsToJoinedRequest : LeftRequestDerivable {
    typealias LeftRowDecoder = Left
    
    func mapLeftRequest(_ transform: (QueryInterfaceRequest<Left>) -> (QueryInterfaceRequest<Left>)) -> BelongsToJoinedRequest<Left, Right> {
        return BelongsToJoinedRequest(leftRequest: transform(leftRequest), association: association)
    }
}

extension BelongsToJoinedRequest : TypedRequest {
    public typealias RowDecoder = JoinedPair<Left, Right>
    
    public func prepare(_ db: Database) throws -> (SelectStatement, RowAdapter?) {
        return try prepareJoinedPairRequest(
            db,
            leftQuery: leftRequest.query,
            rightQuery: association.rightRequest.query,
            joinOperator: .join,
            mapping: association.mapping(db),
            leftScope: RowDecoder.leftScope,
            rightScope: RowDecoder.rightScope)
    }
}

extension QueryInterfaceRequest where RowDecoder: TableMapping {
    public func joined<Right>(with association: BelongsToAssociation<RowDecoder, Right>) -> BelongsToJoinedRequest<RowDecoder, Right> where Right: TableMapping {
        return BelongsToJoinedRequest(leftRequest: self, association: association)
    }
}

extension TableMapping {
    public static func joined<Right>(with association: BelongsToAssociation<Self, Right>) -> BelongsToJoinedRequest<Self, Right> where Right: TableMapping {
        return all().joined(with: association)
    }
}
