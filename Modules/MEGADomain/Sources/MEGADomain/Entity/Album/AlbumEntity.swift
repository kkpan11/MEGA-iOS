import Foundation

public enum AlbumEntityType {
    case raw
    case gif
    case user
}

public struct AlbumEntity: Identifiable, Hashable {
    public let id: HandleEntity
    public let name: String
    public let coverNode: NodeEntity
    public let count: Int
    public let type: AlbumEntityType
    
    public init(id: HandleEntity, name: String, coverNode: NodeEntity, count: Int, type: AlbumEntityType) {
        self.id = id
        self.name = name
        self.coverNode = coverNode
        self.count = count
        self.type = type
    }
}

extension AlbumEntity {
    public func update(name newName: String) -> AlbumEntity {
        AlbumEntity(id: self.id, name: newName, coverNode: self.coverNode, count: self.count, type: self.type)
    }
}
