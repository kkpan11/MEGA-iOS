import Combine
import Foundation
import MEGADomain
import MEGASwift

final public class UserAlbumCacheRepository: UserAlbumRepositoryProtocol {
    public static let newRepo: UserAlbumCacheRepository = UserAlbumCacheRepository(
        userAlbumRepository: UserAlbumRepository.newRepo, 
        userAlbumCache: UserAlbumCache.shared,
        setAndElementsUpdatesProvider: SetAndElementUpdatesProvider(sdk: .sharedSdk))
    
    public var setsUpdatedPublisher: AnyPublisher<[SetEntity], Never> {
        setsUpdatedSourcePublisher.eraseToAnyPublisher()
    }
    public var setElementsUpdatedPublisher: AnyPublisher<[SetElementEntity], Never> {
        setElementsUpdatedSourcePublisher.eraseToAnyPublisher()
    }
    
    private let setsUpdatedSourcePublisher = PassthroughSubject<[SetEntity], Never>()
    private let userAlbumRepository: any UserAlbumRepositoryProtocol
    private let userAlbumCache: any UserAlbumCacheProtocol
    private let setAndElementsUpdatesProvider: any SetAndElementUpdatesProviderProtocol
    private let setElementsUpdatedSourcePublisher = PassthroughSubject<[SetElementEntity], Never>()
    private var monitorSDKUpdatesTask: Task<Void, Error>?
    private let setUpdateSequences = MulticastAsyncSequence<[SetEntity]>()
    
    init(userAlbumRepository: some UserAlbumRepositoryProtocol,
         userAlbumCache: some UserAlbumCacheProtocol,
         setAndElementsUpdatesProvider: some SetAndElementUpdatesProviderProtocol
    ) {
        self.userAlbumRepository = userAlbumRepository
        self.userAlbumCache = userAlbumCache
        self.setAndElementsUpdatesProvider = setAndElementsUpdatesProvider
        
        monitorSDKUpdatesTask = Task {
            await withTaskGroup(of: Void.self, body: { taskGroup in
                taskGroup.addTask { await self.monitorSetUpdates() }
                taskGroup.addTask { await self.monitorSetElementUpdates() }
            })
        }
    }
    
    deinit {
        monitorSDKUpdatesTask?.cancel()
    }
    
    public func albums() async -> [SetEntity] {
        let cachedAlbums = await userAlbumCache.albums
        guard cachedAlbums.isEmpty else {
            return cachedAlbums
        }
        let userAlbums = await userAlbumRepository.albums()
        await userAlbumCache.setAlbums(userAlbums)
        return userAlbums
    }
        
    public func albumsUpdated() async -> AnyAsyncSequence<[SetEntity]> {
        await setUpdateSequences.make()
    }
    
    public func albumContent(by id: HandleEntity, includeElementsInRubbishBin: Bool) async -> [SetElementEntity] {
        await userAlbumRepository.albumContent(by: id, includeElementsInRubbishBin: includeElementsInRubbishBin)
    }
    
    public func albumElement(by id: HandleEntity, elementId: HandleEntity) async -> SetElementEntity? {
        await userAlbumRepository.albumElement(by: id, elementId: elementId)
    }
    
    public func albumElementIds(by id: HandleEntity, includeElementsInRubbishBin: Bool) async -> [AlbumPhotoIdEntity] {
        if let cachedAlbumElementIds = await userAlbumCache.albumElementIds(forAlbumId: id),
           cachedAlbumElementIds.isNotEmpty {
            return cachedAlbumElementIds
        }
        let albumElementIds = await userAlbumRepository.albumElementIds(
            by: id, includeElementsInRubbishBin: includeElementsInRubbishBin)
        await userAlbumCache.setAlbumElementIds(forAlbumId: id, elementIds: albumElementIds)
        return albumElementIds
    }
    
    public func createAlbum(_ name: String?) async throws -> SetEntity {
        try await userAlbumRepository.createAlbum(name)
    }
    
    public func updateAlbumName(_ name: String, _ id: HandleEntity) async throws -> String {
        try await userAlbumRepository.updateAlbumName(name, id)
    }
    
    public func deleteAlbum(by id: HandleEntity) async throws -> HandleEntity {
        try await userAlbumRepository.deleteAlbum(by: id)
    }
    
    public func addPhotosToAlbum(by id: HandleEntity, nodes: [NodeEntity]) async throws -> AlbumElementsResultEntity {
        try await userAlbumRepository.addPhotosToAlbum(by: id, nodes: nodes)
    }
    
    public func updateAlbumElementName(albumId: HandleEntity, elementId: HandleEntity, name: String) async throws -> String {
        try await userAlbumRepository.updateAlbumElementName(albumId: albumId, elementId: elementId, name: name)
    }
    
    public func updateAlbumElementOrder(albumId: HandleEntity, elementId: HandleEntity, order: Int64) async throws -> Int64 {
        try await userAlbumRepository.updateAlbumElementOrder(albumId: albumId, elementId: elementId, order: order)
    }
    
    public func deleteAlbumElements(albumId: HandleEntity, elementIds: [HandleEntity]) async throws -> AlbumElementsResultEntity {
        try await userAlbumRepository.deleteAlbumElements(albumId: albumId, elementIds: elementIds)
    }
    
    public func updateAlbumCover(for albumId: HandleEntity, elementId: HandleEntity) async throws -> HandleEntity {
        try await userAlbumRepository.updateAlbumCover(for: albumId, elementId: elementId)
    }
    
    private func monitorSetUpdates() async {
        for await setUpdates in setAndElementsUpdatesProvider.setUpdates(filteredBy: [.album]) {
            guard !Task.isCancelled else {
                await setUpdateSequences.terminateContinuations()
                break
            }
            
            let (insertions, deletions) = setUpdates
                .reduce(into: (insertions: [SetEntity], deletions: [SetEntity])([], [])) { result, setEntity in
                    if setEntity.changeTypes.contains(.removed) {
                        result.deletions.append(setEntity)
                    } else {
                        result.insertions.append(setEntity.copyWithModified(changeTypes: []))
                    }
                }
            await userAlbumCache.remove(albums: deletions)
            await userAlbumCache.setAlbums(insertions)
            
            let updatedAlbums = await albums()
            
            setsUpdatedSourcePublisher.send(updatedAlbums)
            
            await setUpdateSequences.yield(element: updatedAlbums)
        }
    }
    
    private func monitorSetElementUpdates() async {
        for await setElementUpdate in setAndElementsUpdatesProvider.setElementUpdates() {
            guard !Task.isCancelled else {
                break
            }

            let invalidateAlbumSets = Set(setElementUpdate.map(\.ownerId))
            
            await userAlbumCache.removeElements(of: invalidateAlbumSets)
            
            setElementsUpdatedSourcePublisher.send(setElementUpdate)
        }
    }
}

fileprivate extension SetEntity {
    func copyWithModified(handle: HandleEntity? = nil, userId: HandleEntity? = nil, coverId: HandleEntity? = nil, creationTime: Date? = nil, modificationTime: Date? = nil, setType: SetTypeEntity? = nil, name: String? = nil, isExported: Bool? = nil, changeTypes: SetChangeTypeEntity? = nil) -> SetEntity {
        
        SetEntity(
            handle: handle ?? self.handle,
            userId: userId ?? self.userId,
            coverId: coverId ?? self.coverId,
            creationTime: creationTime ?? self.creationTime,
            modificationTime: modificationTime ?? self.modificationTime,
            setType: setType ?? self.setType,
            name: name ?? self.name,
            isExported: isExported ?? self.isExported,
            changeTypes: changeTypes ?? self.changeTypes)
    }
}
