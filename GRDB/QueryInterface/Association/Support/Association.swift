public protocol Association : RightRequestDerivable {
    associatedtype LeftAssociated: TableMapping
    associatedtype RightAssociated: TableMapping

    var rightRequest: QueryInterfaceRequest<RightAssociated> { get }
    func mapping(_ db: Database) throws -> [(left: String, right: String)]
    
    func mapRightRequest(_ transform: (QueryInterfaceRequest<RightAssociated>) -> QueryInterfaceRequest<RightAssociated>) -> Self
}
