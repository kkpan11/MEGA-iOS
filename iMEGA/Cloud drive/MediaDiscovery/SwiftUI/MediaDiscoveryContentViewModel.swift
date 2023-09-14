import Combine
import Foundation
import MEGADomain
import MEGAFoundation
import MEGAPresentation
import SwiftUI

protocol MediaDiscoveryContentDelegate: AnyObject {
    
    /// This delegate function will be triggered when a change to the currently selected media nodes for this media discovery list  occurs.
    /// When a selection change occurs, this delegate will return the current selected node entities and the a list of all the node entities.
    /// - Parameters:
    ///   - selected: returns currently selected [NodeEntities]
    ///   - allPhotos: returns list of all nodes loaded in this feature
    func selectedPhotos(selected: [NodeEntity], allPhotos: [NodeEntity])
    
    /// This delegate function will get triggered when the ability to enter edit mode/ to be able to select nodes in Media Discovery changes.
    ///  Follow this trigger, to determine the availability to enter multi-select/edit mode.
    /// - Parameter isHidden: Bool value to determine if selection action should be hidden
    func isMediaDiscoverySelection(isHidden: Bool)
}

enum MediaDiscoveryContentViewState {
    case normal
    case empty
}

final class MediaDiscoveryContentViewModel: ObservableObject {
    
    @Published private(set) var viewState: MediaDiscoveryContentViewState = .normal
    let photoLibraryContentViewModel: PhotoLibraryContentViewModel
    let photoLibraryContentViewRouter: PhotoLibraryContentViewRouter
    
    var editMode: EditMode {
        get { photoLibraryContentViewModel.selection.editMode }
        set { photoLibraryContentViewModel.selection.editMode = newValue }
    }
        
    private let parentNode: NodeEntity
    private let analyticsUseCase: any MediaDiscoveryAnalyticsUseCaseProtocol
    private let mediaDiscoveryUseCase: any MediaDiscoveryUseCaseProtocol
    private lazy var pageStayTimeTracker = PageStayTimeTracker()
    private var subscriptions = Set<AnyCancellable>()
    private weak var delegate: (any MediaDiscoveryContentDelegate)?
    
    init(contentMode: PhotoLibraryContentMode,
         parentNode: NodeEntity,
         delegate: (some MediaDiscoveryContentDelegate)?,
         analyticsUseCase: some MediaDiscoveryAnalyticsUseCaseProtocol,
         mediaDiscoveryUseCase: some MediaDiscoveryUseCaseProtocol) {
        
        photoLibraryContentViewModel = PhotoLibraryContentViewModel(library: PhotoLibrary(), contentMode: contentMode)
        photoLibraryContentViewRouter = PhotoLibraryContentViewRouter(contentMode: contentMode)
        
        self.parentNode = parentNode
        self.delegate = delegate
        self.analyticsUseCase = analyticsUseCase
        self.mediaDiscoveryUseCase = mediaDiscoveryUseCase
        
        subscribeToSelectionChanges()
        subscribeToNodeChanges()
    }
    
    @MainActor
    func loadPhotos() async {
        do {
            viewState = .normal
            try Task.checkCancellation()
            let nodes = try await mediaDiscoveryUseCase.nodes(forParent: parentNode)
            try Task.checkCancellation()
            photoLibraryContentViewModel.library = nodes.toPhotoLibrary(withSortType: .newest)
            viewState = nodes.isEmpty ? .empty : .normal
        } catch {
            MEGALogError("Error loading nodes: \(error.localizedDescription)")
        }
    }
    
    func onViewAppear() {
        startTracking()
        analyticsUseCase.sendPageVisitedStats()
    }
    
    func onViewDisappear() {
        endTracking()
        sendPageStayStats()
    }
    
    func toggleAllSelected() {
        photoLibraryContentViewModel.toggleSelectAllPhotos()
    }
    
    private func startTracking() {
        pageStayTimeTracker.start()
    }
    
    private func endTracking() {
        pageStayTimeTracker.end()
    }
    
    private func sendPageStayStats() {
        let duration = Int(pageStayTimeTracker.duration)
        analyticsUseCase.sendPageStayStats(with: duration)
    }
    
    private func subscribeToSelectionChanges() {
        
        photoLibraryContentViewModel
            .$library
            .map(\.allPhotos)
            .combineLatest(photoLibraryContentViewModel.selection.$photos)
            .receive(on: DispatchQueue.main)
            .sink { [weak delegate] allPhotos, selectedPhotos in
                delegate?.selectedPhotos(selected: selectedPhotos.map(\.value), allPhotos: allPhotos)
            }
            .store(in: &subscriptions)
        
        photoLibraryContentViewModel
            .selection
            .$isHidden
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak delegate] in delegate?.isMediaDiscoverySelection(isHidden: $0) }
            .store(in: &subscriptions)
    }
    
    private func subscribeToNodeChanges() {
        
        mediaDiscoveryUseCase
            .nodeUpdatesPublisher
            .debounce(for: .seconds(0.35), scheduler: DispatchQueue.global())
            .sink { [weak self] updatedNodes in
                guard let self else { return }
                
                let nodes = photoLibraryContentViewModel.library.allPhotos
                
                guard mediaDiscoveryUseCase.shouldReload(parentNode: parentNode, loadedNodes: nodes, updatedNodes: updatedNodes) else {
                    return
                }
                
                Task { await self.loadPhotos() }
            }.store(in: &subscriptions)
    }
}
