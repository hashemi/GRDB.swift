public struct HasManyJoinedRequest<Left, Right> where
    Left: TableMapping,
    Right: TableMapping
{
    typealias LeftRequest = QueryInterfaceRequest<Left>
    
    var leftRequest: LeftRequest
    let association: HasManyAssociation<Left, Right>
}

extension HasManyJoinedRequest : LeftRequestDerivable {
    func mapLeftRequest(_ transform: (LeftRequest) -> (LeftRequest)) -> HasManyJoinedRequest<Left, Right> {
        return HasManyJoinedRequest(
            leftRequest: transform(leftRequest),
            association: association)
    }
}

extension HasManyJoinedRequest : TypedRequest {
    public typealias RowDecoder = JoinedPair<Left, Right>
    
    public func prepare(_ db: Database) throws -> (SelectStatement, RowAdapter?) {
        return try prepareJoinedPairRequest(
            db,
            leftQuery: leftRequest.query,
            rightQuery: association.rightRequest.query,
            joinOperator: .innerJoin,
            mapping: association.mapping(db),
            leftScope: RowDecoder.leftScope,
            rightScope: RowDecoder.rightScope)
    }
}

extension QueryInterfaceRequest where RowDecoder: TableMapping {
    public func joined<Right>(with association: HasManyAssociation<RowDecoder, Right>)
        -> HasManyJoinedRequest<RowDecoder, Right>
        where Right: TableMapping
    {
        return HasManyJoinedRequest(leftRequest: self, association: association)
    }
}

extension TableMapping {
    public static func joined<Right>(with association: HasManyAssociation<Self, Right>)
        -> HasManyJoinedRequest<Self, Right>
        where Right: TableMapping
    {
        return all().joined(with: association)
    }
}
