public struct HasManyLeftJoinedRequest<Left, Right> where
    Left: TableMapping,
    Right: TableMapping
{
    typealias LeftRequest = QueryInterfaceRequest<Left>
    
    var leftRequest: LeftRequest
    let association: HasManyAssociation<Left, Right>
}

extension HasManyLeftJoinedRequest : LeftRequestDerivable {
    func mapLeftRequest(_ transform: (LeftRequest) -> (LeftRequest)) -> HasManyLeftJoinedRequest<Left, Right> {
        return HasManyLeftJoinedRequest(
            leftRequest: transform(leftRequest),
            association: association)
    }
}

extension HasManyLeftJoinedRequest : TypedRequest {
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
    public func leftJoined<Right>(with association: HasManyAssociation<RowDecoder, Right>)
        -> HasManyLeftJoinedRequest<RowDecoder, Right>
        where Right: TableMapping
    {
        return HasManyLeftJoinedRequest(leftRequest: self, association: association)
    }
}

extension TableMapping {
    public static func leftJoined<Right>(with association: HasManyAssociation<Self, Right>)
        -> HasManyLeftJoinedRequest<Self, Right>
        where Right: TableMapping
    {
        return all().leftJoined(with: association)
    }
}
