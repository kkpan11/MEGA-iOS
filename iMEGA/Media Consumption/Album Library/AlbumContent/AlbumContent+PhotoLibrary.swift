import Foundation

extension AlbumContentViewController: PhotoLibraryProvider {
    func hideNavigationEditBarButton(_ hide: Bool) {
        if hide {
            navigationItem.rightBarButtonItem = nil
        } else {
            configureRightBarButton()
        }
    }
    
    func showNavigationRightBarButton(_ show: Bool) {
        if show {
            configureRightBarButton()
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }
    
    func setupPhotoLibrarySubscriptions() {
        photoLibraryPublisher.subscribeToSelectedModeChange { [weak self] in
            self?.showNavigationRightBarButton($0 == .all && self?.photoLibraryContentViewModel.library.isEmpty == false)
        }
        
        photoLibraryPublisher.subscribeToSelectedPhotosChange { [weak self] in
            self?.selection.setSelectedNodes(Array($0.values))
            self?.didSelectedPhotoCountChange($0.count)
        }
    }
    
    func didSelectedPhotoCountChange(_ count: Int) {
        updateNavigationTitle(withSelectedPhotoCount: count)
        configureToolbarButtonsWithAlbumType()
    }
}
