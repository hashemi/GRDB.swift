public struct HasOneJoinedRequest<Left, Right> where
    Left: TableMapping,
    Right: TableMapping
{
    public typealias WrappedRequest = QueryInterfaceRequest<Left>
    
    var leftRequest: WrappedRequest
    let association: HasOneAssociation<Left, Right>
}

extension HasOneJoinedRequest : RequestDerivableWrapper {
    public func mapRequest(_ transform: (WrappedRequest) -> (WrappedRequest)) -> HasOneJoinedRequest {
        return HasOneJoinedRequest(
            leftRequest: transform(leftRequest),
            association: association)
    }
}

extension HasOneJoinedRequest : TypedRequest {
    public typealias RowDecoder = JoinedPair<Left, Right>
    
    public func prepare(_ db: Database) throws -> (SelectStatement, RowAdapter?) {
        return try prepareJoinedPairRequest(
            db,
            left: leftRequest.query,
            join: .inner,
            right: association.rightRequest.query,
            on: association.mapping(db),
            leftScope: RowDecoder.leftScope,
            rightScope: RowDecoder.rightScope)
    }
}

extension QueryInterfaceRequest where RowDecoder: TableMapping {
    public func joined<Right>(with association: HasOneAssociation<RowDecoder, Right>)
        -> HasOneJoinedRequest<RowDecoder, Right>
        where Right: TableMapping
    {
        return HasOneJoinedRequest(leftRequest: self, association: association)
    }
}

extension TableMapping {
    public static func joined<Right>(with association: HasOneAssociation<Self, Right>)
        -> HasOneJoinedRequest<Self, Right>
        where Right: TableMapping
    {
        return all().joined(with: association)
    }
}
