public struct HasOneLeftJoinedRequest<Left: TableMapping, Right: TableMapping> {
    var leftRequest: QueryInterfaceRequest<Left>
    let association: HasOneAssociation<Left, Right>
}

extension HasOneLeftJoinedRequest : LeftRequestDerivable {
    typealias LeftRowDecoder = Left
    
    func mapLeftRequest(_ transform: (QueryInterfaceRequest<Left>) -> (QueryInterfaceRequest<Left>)) -> HasOneLeftJoinedRequest<Left, Right> {
        return HasOneLeftJoinedRequest(leftRequest: transform(leftRequest), association: association)
    }
}

extension HasOneLeftJoinedRequest : TypedRequest {
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
    public func leftJoined<Right>(with association: HasOneAssociation<RowDecoder, Right>) -> HasOneLeftJoinedRequest<RowDecoder, Right> where Right: TableMapping {
        return HasOneLeftJoinedRequest(leftRequest: self, association: association)
    }
}

extension TableMapping {
    public static func leftJoined<Right>(with association: HasOneAssociation<Self, Right>) -> HasOneLeftJoinedRequest<Self, Right> where Right: TableMapping {
        return all().leftJoined(with: association)
    }
}
