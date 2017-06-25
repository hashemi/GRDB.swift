public struct HasManyThroughJoinedRequest<Left: TableMapping, Middle: TableMapping, Right: TableMapping> {
    var leftRequest: QueryInterfaceRequest<Left>
    let association: HasManyThroughAssociation<Left, Middle, Right>
}

extension HasManyThroughJoinedRequest : LeftRequestDerivable {
    typealias LeftRowDecoder = Left
    
    func mapLeftRequest(_ transform: (QueryInterfaceRequest<Left>) -> (QueryInterfaceRequest<Left>)) -> HasManyThroughJoinedRequest<Left, Middle, Right> {
        return HasManyThroughJoinedRequest(leftRequest: transform(leftRequest), association: association)
    }
}

extension HasManyThroughJoinedRequest : TypedRequest {
    public typealias RowDecoder = JoinedPair<Left, Right>
    
    public func prepare(_ db: Database) throws -> (SelectStatement, RowAdapter?) {
        fatalError("Not implemented")
    }
}
