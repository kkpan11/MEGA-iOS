import SwiftUI
import MEGADomain
import MEGAPresentation

protocol AlbumListViewRouting {
    func cell(album: AlbumEntity) -> AlbumCell
    func albumContainer(album: AlbumEntity, newAlbumPhotosToAdd: [NodeEntity]?, existingAlbumNames: @escaping () -> [String]) -> AlbumContainerWrapper
}

struct AlbumListViewRouter: AlbumListViewRouting, Routing {
    
    func cell(album: AlbumEntity) -> AlbumCell {
        let vm = AlbumCellViewModel(
            thumbnailUseCase: ThumbnailUseCase(repository: ThumbnailRepository.newRepo),
            album: album
        )
        return AlbumCell(viewModel: vm)
    }
    
    func albumContainer(album: AlbumEntity, newAlbumPhotosToAdd: [NodeEntity]?, existingAlbumNames: @escaping () -> [String]) -> AlbumContainerWrapper {
        return AlbumContainerWrapper(album: album, newAlbumPhotos: newAlbumPhotosToAdd, existingAlbumNames: existingAlbumNames)
    }
    
    @MainActor
    func build() -> UIViewController {
        let filesSearchRepo = FilesSearchRepository.newRepo
        let vm = AlbumListViewModel(
            usecase: AlbumListUseCase(
                albumRepository: AlbumRepository.newRepo,
                userAlbumRepository: UserAlbumRepository.newRepo,
                fileSearchRepository: filesSearchRepo,
                mediaUseCase: MediaUseCase(fileSearchRepo: filesSearchRepo),
                albumContentsUpdateRepository: AlbumContentsUpdateNotifierRepository.newRepo
            ), alertViewModel: TextFieldAlertViewModel(title: Strings.Localizable.CameraUploads.Albums.Create.Alert.title,
                                                       placeholderText: Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder,
                                                       affirmativeButtonTitle: Strings.Localizable.createFolderButton,
                                                       message: nil)
        )
        
        let content = AlbumListView(viewModel: vm,
                                    createAlbumCellViewModel: CreateAlbumCellViewModel(),
                                    router: self)
        
        return UIHostingController(rootView: content)
    }
    func start() {}
}
