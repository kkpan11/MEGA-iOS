import MEGADomain
import MEGASDKRepo
import SwiftUI
import UIKit

public struct AdsSlotRouter<T: View> {
    private weak var presenter: UIViewController?
    private let adsSlotViewController: any AdsSlotViewControllerProtocol
    private let contentView: T
    
    public init(
        adsSlotViewController: some AdsSlotViewControllerProtocol,
        contentView: T,
        presenter: UIViewController? = nil
    ) {
        self.adsSlotViewController = adsSlotViewController
        self.contentView = contentView
        self.presenter = presenter
    }
    
    public func build() -> UIViewController {
        let viewModel = AdsSlotViewModel(adsUseCase: AdsUseCase(repository: AdsRepository.newRepo),
                                         adsSlotChangeStream: AdsSlotChangeStream(adsSlotViewController: adsSlotViewController))
        let adsSlotView = AdsSlotView(viewModel: viewModel, contentView: contentView)
        return UIHostingController(rootView: adsSlotView)
    }
    
    public func start() {
        presenter?.present(build(), animated: true)
    }
}
