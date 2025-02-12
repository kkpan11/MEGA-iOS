import Combine
import MEGADomain
import MEGAL10n

@MainActor
public final class AddToCollectionViewModel: ObservableObject {
    @Published public var isAddButtonDisabled: Bool = true
    @Published public var showBottomBar: Bool = false
    
    let mode: AddToMode
    let addToAlbumsViewModel: AddToAlbumsViewModel
    let addToPlaylistViewModel: AddToPlaylistViewModel
    
    private let selectedPhotos: [NodeEntity]
    
    public var title: String {
        switch mode {
        case .album: Strings.Localizable.Set.AddTo.album
        case .collection: Strings.Localizable.Set.addTo
        }
    }
    
    public init(
        mode: AddToMode,
        selectedPhotos: [NodeEntity],
        addToAlbumsViewModel: AddToAlbumsViewModel,
        addToPlaylistViewModel: AddToPlaylistViewModel
    ) {
        self.mode = mode
        self.selectedPhotos = selectedPhotos
        self.addToAlbumsViewModel = addToAlbumsViewModel
        self.addToPlaylistViewModel = addToPlaylistViewModel
        
        addToAlbumsViewModel.isAddButtonDisabled
            .assign(to: &$isAddButtonDisabled)
        addToAlbumsViewModel.isItemsNotEmptyPublisher
            .assign(to: &$showBottomBar)
    }
    
    public func addToCollectionTapped() {
        addToAlbumsViewModel.addItems(selectedPhotos)
    }
}
