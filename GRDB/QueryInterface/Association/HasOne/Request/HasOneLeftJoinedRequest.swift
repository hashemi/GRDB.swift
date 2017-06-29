public struct HasOneLeftJoinedRequest<Left, Right> where
    Left: TableMapping,
    Right: TableMapping
{
    public typealias WrappedRequest = QueryInterfaceRequest<Left>
    
    var leftRequest: WrappedRequest
    let association: HasOneAssociation<Left, Right>
}

extension HasOneLeftJoinedRequest : RequestDerivableWrapper {
    public func mapRequest(_ transform: (WrappedRequest) -> (WrappedRequest)) -> HasOneLeftJoinedRequest {
        return HasOneLeftJoinedRequest(leftRequest: transform(leftRequest), association: association)
    }
}

extension HasOneLeftJoinedRequest : TypedRequest {
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
    public func leftJoined<Right>(with association: HasOneAssociation<RowDecoder, Right>)
        -> HasOneLeftJoinedRequest<RowDecoder, Right>
        where Right: TableMapping
    {
        return HasOneLeftJoinedRequest(leftRequest: self, association: association)
    }
}

extension TableMapping {
    public static func leftJoined<Right>(with association: HasOneAssociation<Self, Right>)
        -> HasOneLeftJoinedRequest<Self, Right>
        where Right: TableMapping
    {
        return all().leftJoined(with: association)
    }
}
