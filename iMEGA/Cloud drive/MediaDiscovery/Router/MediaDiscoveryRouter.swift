import UIKit
import MEGADomain
import MEGAPresentation
import MEGAData

@objc final class MediaDiscoveryRouter: NSObject, Routing {
    private weak var presenter: UIViewController?
    private let parentNode: MEGANode
    private let isFolderLink: Bool
    
    @objc init(viewController: UIViewController?, parentNode: MEGANode, isFolderLink: Bool = false) {
        self.presenter = viewController
        self.parentNode = parentNode
        self.isFolderLink = isFolderLink
        
        super.init()
    }
    
    func build() -> UIViewController {
        let parentNode = parentNode.toNodeEntity()
        let sdk = isFolderLink ? MEGASdk.sharedFolderLink : MEGASdk.shared
        let analyticsUseCase = MediaDiscoveryAnalyticsUseCase(repository: AnalyticsRepository.newRepo)
        let mediaDiscoveryUseCase = MediaDiscoveryUseCase(mediaDiscoveryRepository: MediaDiscoveryRepository(sdk: sdk),
                                                          nodeUpdateRepository: NodeUpdateRepository(sdk: sdk))
        let viewModel = MediaDiscoveryViewModel(parentNode: parentNode, router: self, analyticsUseCase: analyticsUseCase,
                                                mediaDiscoveryUseCase: mediaDiscoveryUseCase)
        return MediaDiscoveryViewController(viewModel: viewModel, folderName: parentNode.name,
                                            contentMode: isFolderLink ? .mediaDiscoveryFolderLink : .mediaDiscovery)
    }
    
    func start() {
        guard let presenter = presenter else {
            MEGALogDebug("Unable to start Media Discovery Screen as presented controller is nil")
            return
        }
        
        let nav = MEGANavigationController(rootViewController: build())
        nav.modalPresentationStyle = .fullScreen
        presenter.present(nav, animated: true, completion: nil)
    }
}
