import AsyncAlgorithms
import Combine
import ContentLibraries
import Foundation
import MEGADomain
import MEGAPresentation
import MEGASwift

@MainActor
public final class VisualMediaSearchResultsViewModel: ObservableObject {
    enum ViewState: Equatable {
        case loading
        case empty
        case recentlySearched(items: [SearchHistoryItem])
        case searchResults(albums: [AlbumCellViewModel], photos: [PhotoSearchResultItemViewModel])
    }
    @Published private(set) var viewState: ViewState = .loading
    @Published var searchText = ""
    @Published var selectedRecentlySearched: String?
    
    private let visualMediaSearchHistoryUseCase: any VisualMediaSearchHistoryUseCaseProtocol
    private let monitorAlbumsUseCase: any MonitorAlbumsUseCaseProtocol
    private let thumbnailLoader: any ThumbnailLoaderProtocol
    private let monitorUserAlbumPhotosUseCase: any MonitorUserAlbumPhotosUseCaseProtocol
    private let nodeUseCase: any NodeUseCaseProtocol
    private let sensitiveNodeUseCase: any SensitiveNodeUseCaseProtocol
    private let sensitiveDisplayPreferenceUseCase: any SensitiveDisplayPreferenceUseCaseProtocol
    private let albumCoverUseCase: any AlbumCoverUseCaseProtocol
    private let monitorPhotosUseCase: any MonitorPhotosUseCaseProtocol
    private let contentLibrariesConfiguration: ContentLibraries.Configuration
    private let searchDebounceTime: DispatchQueue.SchedulerTimeType.Stride
    private let debounceQueue: DispatchQueue
    
    private var searchTask: Task<Void, any Error>? {
        didSet { oldValue?.cancel() }
    }
    
    public init(
        searchBarTextFieldUpdater: SearchBarTextFieldUpdater,
        visualMediaSearchHistoryUseCase: some VisualMediaSearchHistoryUseCaseProtocol,
        monitorAlbumsUseCase: some MonitorAlbumsUseCaseProtocol,
        thumbnailLoader: some ThumbnailLoaderProtocol,
        monitorUserAlbumPhotosUseCase: some MonitorUserAlbumPhotosUseCaseProtocol,
        nodeUseCase: some NodeUseCaseProtocol,
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol,
        sensitiveDisplayPreferenceUseCase: some SensitiveDisplayPreferenceUseCaseProtocol,
        albumCoverUseCase: some AlbumCoverUseCaseProtocol,
        monitorPhotosUseCase: some MonitorPhotosUseCaseProtocol,
        contentLibrariesConfiguration: ContentLibraries.Configuration = ContentLibraries.configuration,
        searchDebounceTime: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(300),
        debounceQueue: DispatchQueue = DispatchQueue(label: "nz.mega.VisualMediaSearchDebounceQueue", qos: .userInitiated)
    ) {
        self.visualMediaSearchHistoryUseCase = visualMediaSearchHistoryUseCase
        self.monitorAlbumsUseCase = monitorAlbumsUseCase
        self.thumbnailLoader = thumbnailLoader
        self.monitorUserAlbumPhotosUseCase = monitorUserAlbumPhotosUseCase
        self.nodeUseCase = nodeUseCase
        self.sensitiveNodeUseCase = sensitiveNodeUseCase
        self.sensitiveDisplayPreferenceUseCase = sensitiveDisplayPreferenceUseCase
        self.albumCoverUseCase = albumCoverUseCase
        self.contentLibrariesConfiguration = contentLibrariesConfiguration
        self.monitorPhotosUseCase = monitorPhotosUseCase
        self.searchDebounceTime = searchDebounceTime
        self.debounceQueue = debounceQueue
        
        $selectedRecentlySearched
            .assign(to: &searchBarTextFieldUpdater.$searchBarText)
    }
    
    func monitorSearchResults() async {
        let searchText = $searchText
            .debounceImmediate(for: searchDebounceTime, scheduler: debounceQueue)
            .removeDuplicates()
        
        for await searchQuery in searchText.values {
            performSearch(searchText: searchQuery)
        }
    }
    
    func saveSearch() async {
        guard searchText.isNotEmpty else { return }
        
        await visualMediaSearchHistoryUseCase.add(entry: .init(id: UUID(), query: searchText, searchDate: Date()))
    }
    
    private func performSearch(searchText: String) {
        searchTask = Task {
            guard searchText.isNotEmpty else {
                try await loadRecentlySearchedItems()
                return
            }
            
            if shouldShowLoading() {
                viewState = .loading
            }
            
            try Task.checkCancellation()
            
            try await loadVisualMedia(for: searchText)
        }
    }
    
    private func loadRecentlySearchedItems() async throws {
        let searchHistoryItems = await visualMediaSearchHistoryUseCase.history()
        
        try Task.checkCancellation()
        
        viewState = if searchHistoryItems.isNotEmpty {
            .recentlySearched(items: searchHistoryItems.toSearchHistoryItems())
        } else {
            .empty
        }
    }
    
    private func shouldShowLoading() -> Bool {
        guard viewState != .loading else { return false }
        
        return switch viewState {
        case .empty, .recentlySearched: true
        default: false
        }
    }
    
    private func loadVisualMedia(for searchText: String) async throws {
        let excludeSensitives = await sensitiveDisplayPreferenceUseCase.excludeSensitives()
        try Task.checkCancellation()
        let albumsSequence = try await albumCellViewModelsSequence(
            excludeSensitives: excludeSensitives, searchText: searchText)
        try Task.checkCancellation()
        let photosSequence = await photoSearchResultItemViewModelsSequence(
            excludeSensitives: excludeSensitives, searchText: searchText)
        try Task.checkCancellation()
        
        for await (albumCellViewModels, photoSearchResultItemViewModels) in combineLatest(albumsSequence, photosSequence) {
            viewState = .searchResults(albums: albumCellViewModels, photos: photoSearchResultItemViewModels)
        }
    }
    
    private func albumCellViewModelsSequence(
        excludeSensitives: Bool,
        searchText: String
    ) async throws -> AnyAsyncSequence<[AlbumCellViewModel]> {
        try await monitorAlbumsUseCase.monitorAlbums(
            excludeSensitives: excludeSensitives,
            searchText: searchText)
        .compactMap { [weak self] albums -> [AlbumCellViewModel]? in
            try await self?.map(albums: albums)
        }
        .eraseToAnyAsyncSequence()
    }
    
    private func map(
        albums: [AlbumEntity]
    ) throws -> [AlbumCellViewModel] {
        try albums.map {
            try Task.checkCancellation()
            return AlbumCellViewModel(
                thumbnailLoader: thumbnailLoader,
                monitorUserAlbumPhotosUseCase: monitorUserAlbumPhotosUseCase,
                nodeUseCase: nodeUseCase,
                sensitiveNodeUseCase: sensitiveNodeUseCase,
                sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
                albumCoverUseCase: albumCoverUseCase,
                album: $0,
                selection: AlbumSelection(),
                selectedAlbum: .constant(nil),
                configuration: contentLibrariesConfiguration
            )
        }
    }
    
    private func photoSearchResultItemViewModelsSequence(
        excludeSensitives: Bool,
        searchText: String
    ) async -> AnyAsyncSequence<[PhotoSearchResultItemViewModel]> {
        await monitorPhotosUseCase.monitorPhotos(filterOptions: [.allLocations, .allMedia], excludeSensitive: excludeSensitives, searchText: searchText)
            .compactMap { [weak self] photoResult -> [PhotoSearchResultItemViewModel]? in
                guard let self else { return nil }
                var photos = (try? photoResult.get()) ?? []
                try photos.sort {
                    try Task.checkCancellation()
                    return if $0.modificationTime == $1.modificationTime {
                        $0.handle > $1.handle
                    } else {
                        $0.modificationTime < $1.modificationTime
                    }
                }
                return try photos
                    .map { photo in
                        try Task.checkCancellation()
                        return PhotoSearchResultItemViewModel(
                            photo: photo,
                            thumbnailLoader: thumbnailLoader,
                            searchText: searchText)
                    }
            }
            .eraseToAnyAsyncSequence()
    }
}