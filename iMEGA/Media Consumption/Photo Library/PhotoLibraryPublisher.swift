import Foundation
import Combine

final class PhotoLibraryPublisher {
    private var subscriptions = Set<AnyCancellable>()
    
    let viewModel: PhotoLibraryContentViewModel
    
    init(viewModel: PhotoLibraryContentViewModel) {
        self.viewModel = viewModel
    }
    
    func subscribeToSelectedModeChange(observer: @escaping (PhotoLibraryViewMode) -> Void) {
        viewModel
            .$selectedMode
            .sink {
                observer($0)
            }
            .store(in: &subscriptions)
    }
    
    func subscribeToSelectedPhotosChange(observer: @escaping ([MEGAHandle: NodeEntity]) -> Void) {
        viewModel
            .selection
            .$photos
            .dropFirst()
            .sink {
                observer($0)
            }
            .store(in: &subscriptions)
    }
    
    func cancelSubscriptions() {
        subscriptions.removeAll()
    }
}
