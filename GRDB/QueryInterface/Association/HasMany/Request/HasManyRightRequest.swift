public struct HasManyRightRequest<Left: MutablePersistable, Right: TableMapping> {
    let record: Left
    let association: HasManyAssociation<Left, Right>
}

extension HasManyRightRequest : TypedRequest {
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

extension HasManyRightRequest : RightRequestDerivable {
    typealias RightRowDecoder = Right
    func mapRightRequest(_ transform: (QueryInterfaceRequest<Right>) -> QueryInterfaceRequest<Right>) -> HasManyRightRequest<Left, Right> {
        return HasManyRightRequest(record: record, association: association.mapRightRequest(transform))
    }
}

extension HasManyAssociation where Left: MutablePersistable {
    func makeRequest(from record: Left) -> HasManyRightRequest<Left, Right> {
        return HasManyRightRequest(record: record, association: self)
    }
}

extension MutablePersistable {
    public func makeRequest<Right>(_ association: HasManyAssociation<Self, Right>) -> HasManyRightRequest<Self, Right> where Right: TableMapping {
        return association.makeRequest(from: self)
    }
    
    public func fetchCursor<Right>(_ db: Database, _ association: HasManyAssociation<Self, Right>) throws -> DatabaseCursor<Right> where Right: TableMapping & RowConvertible {
        return try association.makeRequest(from: self).fetchCursor(db)
    }
    
    public func fetchAll<Right>(_ db: Database, _ association: HasManyAssociation<Self, Right>) throws -> [Right] where Right: TableMapping & RowConvertible {
        return try association.makeRequest(from: self).fetchAll(db)
    }
    
    public func fetchOne<Right>(_ db: Database, _ association: HasManyAssociation<Self, Right>) throws -> Right? where Right: TableMapping & RowConvertible {
        return try association.makeRequest(from: self).fetchOne(db)
    }
}