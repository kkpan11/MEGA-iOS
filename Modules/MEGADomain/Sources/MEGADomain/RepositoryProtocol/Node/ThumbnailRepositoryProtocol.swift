import Foundation

public protocol ThumbnailRepositoryProtocol {
    func cachedThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) -> URL?
    func generateCachingURL(for node: NodeEntity, type: ThumbnailTypeEntity) -> URL
    func generateCachingURL(for base64Handle: Base64HandleEntity, type: ThumbnailTypeEntity) -> URL
    func loadThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity, completion: @escaping (Result<URL, ThumbnailErrorEntity>) -> Void)
    
    /// Load thumbnail for a `NodeEntity`
    /// - Parameters:
    ///   - node: The node entity
    ///   - type: The type of the thumbnail
    /// - Returns: The URL of the loaded thumbnail
    /// - Throws: An error of `ThumbnailErrorEntity`
    func loadThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) async throws -> URL
    func cachedPreviewOrOriginalPath(for node: NodeEntity) -> String?
}
