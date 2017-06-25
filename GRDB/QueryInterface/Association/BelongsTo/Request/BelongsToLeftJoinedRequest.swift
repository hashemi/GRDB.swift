public struct BelongsToLeftJoinedRequest<Left: TableMapping, Right: TableMapping> {
    var leftRequest: QueryInterfaceRequest<Left>
    let association: BelongsToAssociation<Left, Right>
}

extension BelongsToLeftJoinedRequest : LeftRequestDerivable {
    typealias LeftRowDecoder = Left
    
    func mapLeftRequest(_ transform: (QueryInterfaceRequest<Left>) -> (QueryInterfaceRequest<Left>)) -> BelongsToLeftJoinedRequest<Left, Right> {
        return BelongsToLeftJoinedRequest(leftRequest: transform(leftRequest), association: association)
    }
}

extension BelongsToLeftJoinedRequest : TypedRequest {
    public typealias RowDecoder = JoinedPair<Left, Right?>
    
    public func prepare(_ db: Database) throws -> (SelectStatement, RowAdapter?) {
        return try prepareJoinedPairRequest(
            db,
            leftQuery: leftRequest.query,
            rightQuery: association.rightRequest.query,
            joinOperator: .leftJoin,
            mapping: association.mapping(db),
            leftScope: RowDecoder.leftScope,
            rightScope: RowDecoder.rightScope)
    }
}

extension QueryInterfaceRequest where RowDecoder: TableMapping {
    public func leftJoined<Right>(with association: BelongsToAssociation<RowDecoder, Right>) -> BelongsToLeftJoinedRequest<RowDecoder, Right> where Right: TableMapping {
        return BelongsToLeftJoinedRequest(leftRequest: self, association: association)
    }
}

extension TableMapping {
    public static func leftJoined<Right>(with association: BelongsToAssociation<Self, Right>) -> BelongsToLeftJoinedRequest<Self, Right> where Right: TableMapping {
        return all().leftJoined(with: association)
    }
}