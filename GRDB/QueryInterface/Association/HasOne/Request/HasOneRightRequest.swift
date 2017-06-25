public struct HasOneRightRequest<Left: MutablePersistable, Right: TableMapping> {
    let record: Left
    let association: HasOneAssociation<Left, Right>
}

extension HasOneRightRequest : TypedRequest {
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

extension HasOneRightRequest : RightRequestDerivable {
    typealias RightRowDecoder = Right
    func mapRightRequest(_ transform: (QueryInterfaceRequest<Right>) -> QueryInterfaceRequest<Right>) -> HasOneRightRequest<Left, Right> {
        return HasOneRightRequest(record: record, association: association.mapRightRequest(transform))
    }
}

extension HasOneAssociation where Left: MutablePersistable {
    func makeRequest(from record: Left) -> HasOneRightRequest<Left, Right> {
        return HasOneRightRequest(record: record, association: self)
    }
}

extension MutablePersistable {
    public func makeRequest<Right>(_ association: HasOneAssociation<Self, Right>) -> HasOneRightRequest<Self, Right> where Right: TableMapping {
        return association.makeRequest(from: self)
    }
    
    public func fetchOne<Right>(_ db: Database, _ association: HasOneAssociation<Self, Right>) throws -> Right? where Right: TableMapping & RowConvertible {
        return try association.makeRequest(from: self).fetchOne(db)
    }
}
