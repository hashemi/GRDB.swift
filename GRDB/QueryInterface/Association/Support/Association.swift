public protocol Association {
    associatedtype LeftAssociated: TableMapping
    associatedtype RightAssociated: TableMapping

    var rightRequest: QueryInterfaceRequest<RightAssociated> { get }
    func mapping(_ db: Database) throws -> [(left: String, right: String)]
}

public protocol AssociationToOne : Association {
}
