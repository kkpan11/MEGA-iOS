@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

final class BannerContainerViewModelTests: XCTestCase {
    
    func testAction_onViewWillAppear() {
        let sut = makeSUT(withOfflineLogOutWarningDismissed: true)
        test(viewModel: sut.viewModel, action: .onViewWillAppear, expectedCommands: [.hideBanner(animated: false)])
    }
    
    func testAction_OnViewDidLoad_WarningDismissed() {
        let sut = makeSUT()
        
        XCTAssertTrue(sut.preference[.offlineLogOutWarningDismissed] == Optional<Bool>.none)
        test(viewModel: sut.viewModel, action: .onClose, expectedCommands: [.hideBanner(animated: true)])
        
        XCTAssertTrue(sut.preference[.offlineLogOutWarningDismissed] == true)
        test(viewModel: sut.viewModel, action: .onViewDidLoad(UITraitCollection()), expectedCommands: [])
    }
    
    func testAction_OnViewDidLoad_WarningNotDismissed() {
        let sut = makeSUT()
        
        XCTAssertTrue(sut.preference[.offlineLogOutWarningDismissed] == Optional<Bool>.none)
        test(viewModel: sut.viewModel,
             action: .onViewDidLoad(UITraitCollection()),
             expectedCommands: [.configureView(message: "Banner message example",
                                               backgroundColor: BannerType.warning.bgColor,
                                               textColor: BannerType.warning.textColor,
                                               actionIcon: BannerType.warning.actionIcon)])
    }
    
    func testAction_OnTrailCollectionDidChange() {
        test(viewModel: makeSUT().viewModel,
             action: .onTraitCollectionDidChange(UITraitCollection()),
             expectedCommands: [
                .configureView(message: "Banner message example",
                               backgroundColor: BannerType.warning.bgColor,
                               textColor: BannerType.warning.textColor,
                               actionIcon: BannerType.warning.actionIcon)])
    }
    
    func testAction_onClose() {
        test(viewModel: makeSUT().viewModel, action: .onClose, expectedCommands: [.hideBanner(animated: true)])
    }
    
    // MARK: - Private methods
    
    private func makeSUT(
        withOfflineLogOutWarningDismissed offlineLogOutWarningDismissed: Bool? = nil
    ) -> (viewModel: BannerContainerViewModel, preference: some PreferenceUseCaseProtocol) {
        let preferenceUseCase = MockPreferenceUseCase()
        if let offlineLogOutWarningDismissed {
            preferenceUseCase.dict[.offlineLogOutWarningDismissed] = offlineLogOutWarningDismissed
        }
        
        return (BannerContainerViewModel(
            router: MockBannerContainerViewRouter(),
            message: "Banner message example",
            type: .warning,
            preferenceUseCase: preferenceUseCase
        ), preferenceUseCase)
    }
}
