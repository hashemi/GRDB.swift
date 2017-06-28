public struct BelongsToLeftJoinedRequest<Left, Right> where
    Left: TableMapping,
    Right: TableMapping
{
    typealias LeftRequest = QueryInterfaceRequest<Left>
    
    var leftRequest: LeftRequest
    let association: BelongsToAssociation<Left, Right>
}

extension BelongsToLeftJoinedRequest : LeftRequestDerivable {
    func mapLeftRequest(_ transform: (LeftRequest) -> (LeftRequest)) -> BelongsToLeftJoinedRequest<Left, Right> {
        return BelongsToLeftJoinedRequest(
            leftRequest: transform(leftRequest),
            association: association)
    }
}

extension BelongsToLeftJoinedRequest : TypedRequest {
    public typealias RowDecoder = JoinedPair<Left, Right?>
    
    public func prepare(_ db: Database) throws -> (SelectStatement, RowAdapter?) {
        return try prepareJoinedPairRequest(
            db,
            left: leftRequest.query,
            join: .left,
            right: association.rightRequest.query,
            on: association.mapping(db),
            leftScope: RowDecoder.leftScope,
            rightScope: RowDecoder.rightScope)
    }
}

extension QueryInterfaceRequest where RowDecoder: TableMapping {
    public func leftJoined<Right>(with association: BelongsToAssociation<RowDecoder, Right>)
        -> BelongsToLeftJoinedRequest<RowDecoder, Right>
        where Right: TableMapping
    {
        return BelongsToLeftJoinedRequest(leftRequest: self, association: association)
    }
}

extension TableMapping {
    public static func leftJoined<Right>(with association: BelongsToAssociation<Self, Right>)
        -> BelongsToLeftJoinedRequest<Self, Right>
        where Right: TableMapping
    {
        return all().leftJoined(with: association)
    }
}
