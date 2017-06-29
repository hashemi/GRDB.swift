public struct BelongsToRequest<Left, Right> where
    Left: MutablePersistable,
    Right: TableMapping
{
    let record: Left
    let association: BelongsToAssociation<Left, Right>
}

extension BelongsToRequest : RequestDerivableWrapper {
    public typealias WrappedRequest = BelongsToAssociation<Left, Right>.WrappedRequest
    
    public func mapRequest(_ transform: (WrappedRequest) -> WrappedRequest) -> BelongsToRequest {
        return BelongsToRequest(
            record: record,
            association: association.mapRequest(transform))
    }
}

extension BelongsToRequest : TypedRequest {
    public typealias RowDecoder = Right
    
    public func prepare(_ db: Database) throws -> (SelectStatement, RowAdapter?) {
        let mapping = try association.mapping(db)
        let container = PersistenceContainer(record)
        let rowValue = RowValue(mapping.map { container[caseInsensitive: $0.left]?.databaseValue ?? .null })
        return try association.rightRequest
            .filter(mapping.map { Column($0.right) } == rowValue)
            .prepare(db)
    }
}

extension BelongsToAssociation where Left: MutablePersistable {
    func makeRequest(from record: Left) -> BelongsToRequest<Left, Right> {
        return BelongsToRequest(record: record, association: self)
    }
}

extension MutablePersistable {
    public func makeRequest<Right>(_ association: BelongsToAssociation<Self, Right>)
        -> BelongsToRequest<Self, Right>
        where Right: TableMapping
    {
        return association.makeRequest(from: self)
    }
    
    public func fetchOne<Right>(_ db: Database, _ association: BelongsToAssociation<Self, Right>) throws
        -> Right?
        where Right: TableMapping & RowConvertible
    {
        return try association.makeRequest(from: self).fetchOne(db)
    }
}
