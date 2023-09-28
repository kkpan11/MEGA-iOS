import Foundation
import MEGAAnalyticsiOS
import MEGADomain
import MEGAL10n
import MEGAPermissions
import MEGAPresentation
import MEGASDKRepo
import MEGASwift
import Search
import SwiftUI

final class HomeScreenFactory: NSObject {
    
    private var sdk: MEGASdk {
        MEGASdk.sharedSdk
    }
    
    func createHomeScreen(
        from tabBarController: MainTabBarController,
        newHomeSearchResultsEnabled: Bool,
        tracker: some AnalyticsTracking
    ) -> UIViewController {
        let homeViewController = HomeViewController()
        let navigationController = MEGANavigationController(rootViewController: homeViewController)
        
        let myAvatarViewModel = MyAvatarViewModel(
            megaNotificationUseCase: MEGANotificationUseCase(
                userAlertsClient: .live
            ),
            megaAvatarUseCase: MEGAavatarUseCase(
                megaAvatarClient: .live,
                avatarFileSystemClient: .live,
                accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
                thumbnailRepo: ThumbnailRepository.newRepo,
                handleUseCase: MEGAHandleUseCase(repo: MEGAHandleRepository.newRepo)
            ),
            megaAvatarGeneratingUseCase: MEGAAavatarGeneratingUseCase(
                storeUserClient: .live,
                megaAvatarClient: .live,
                accountUseCase: AccountUseCase(repository: AccountRepository.newRepo)
            )
        )
        
        let permissionHandler: some DevicePermissionsHandling = DevicePermissionsHandler.makeHandler()
        
        let uploadViewModel = HomeUploadingViewModel(
            uploadFilesUseCase: UploadPhotoAssetsUseCase(
                uploadPhotoAssetsRepository: UploadPhotoAssetsRepository(store: MEGAStore.shareInstance())
            ),
            permissionHandler: permissionHandler,
            networkMonitorUseCase: NetworkMonitorUseCase(repo: NetworkMonitorRepository()),
            createContextMenuUseCase: CreateContextMenuUseCase(repo: CreateContextMenuRepository.newRepo),
            router: FileUploadingRouter(navigationController: navigationController, baseViewController: homeViewController)
        )
        
        homeViewController.myAvatarViewModel = myAvatarViewModel
        homeViewController.uploadViewModel = uploadViewModel
        homeViewController.startConversationViewModel = StartConversationViewModel(
            networkMonitorUseCase: NetworkMonitorUseCase(repo: NetworkMonitorRepository()),
            router: NewChatRouter(
                navigationController: navigationController,
                tabBarController: tabBarController
            )
        )
        homeViewController.recentsViewModel = HomeRecentActionViewModel(
            permissionHandler: permissionHandler,
            nodeFavouriteActionUseCase: NodeFavouriteActionUseCase(
                nodeFavouriteRepository: NodeFavouriteActionRepository.newRepo
            ),
            saveMediaToPhotosUseCase: SaveMediaToPhotosUseCase(
                downloadFileRepository: DownloadFileRepository(sdk: sdk),
                fileCacheRepository: FileCacheRepository.newRepo,
                nodeRepository: makeNodeRepo()
            )
        )
        homeViewController.bannerViewModel = HomeBannerViewModel(
            userBannerUseCase: UserBannerUseCase(
                userBannerRepository: BannerRepository.newRepo
            ),
            router: HomeBannerRouter(navigationController: navigationController)
        )
        
        homeViewController.quickAccessWidgetViewModel = QuickAccessWidgetViewModel(
            offlineFilesUseCase: OfflineFilesUseCase(
                repo: OfflineFileFetcherRepository.newRepo
            )
        )
        
        navigationController.tabBarItem = UITabBarItem(title: nil, image: Asset.Images.TabBarIcons.home.image, selectedImage: nil)
        
        let bridge = SearchResultsBridge()
        homeViewController.searchResultsBridge = bridge
        
        let searchResultViewController = makeSearchResultViewController(
            with: navigationController,
            bridge: bridge,
            newHomeSearchResultsEnabled: newHomeSearchResultsEnabled,
            tracker: tracker
        )
        
        homeViewController.searchResultViewController = searchResultViewController
        
        let router = HomeRouter(
            navigationController: navigationController,
            tabBarController: tabBarController
        )
        homeViewController.router = router
        homeViewController.homeViewModel = HomeViewModel(
            shareUseCase: ShareUseCase(repo: ShareRepository.newRepo),
            tracker: tracker
        )
        
        return navigationController
    }
    
    private func makeNodeRepo() -> some NodeRepositoryProtocol {
        NodeRepository.newRepo
    }
    
    private func makeSearchResultViewController(
        with navigationController: UINavigationController,
        bridge: SearchResultsBridge,
        newHomeSearchResultsEnabled: Bool,
        tracker: some AnalyticsTracking
    ) -> UIViewController {
        
        if newHomeSearchResultsEnabled {
            return makeNewSearchResultsViewController(
                with: navigationController,
                bridge: bridge,
                tracker: tracker
            )
        } else {
            return makeLegacySearchResultsViewController(
                with: navigationController,
                bridge: bridge,
                tracker: tracker
            )
        }
    }
    
    private func nodeActionListener(_ tracker: any AnalyticsTracking) -> (MegaNodeActionType?) -> Void {
        { action in
            switch action {
            case .saveToPhotos:
                tracker.trackAnalyticsEvent(with: SearchResultSaveToDeviceMenuItemEvent())
            case .manageLink, .shareLink:
                tracker.trackAnalyticsEvent(with: SearchResultShareMenuItemEvent())
            default:
                {}() // we do not track other events here yet
            }
        }
    }
    
    private func makeNewSearchResultsViewController(
        with navigationController: UINavigationController,
        bridge: SearchResultsBridge,
        tracker: some AnalyticsTracking
    ) -> UIViewController {
        
        let router = HomeSearchResultRouter(
            navigationController: navigationController,
            nodeActionViewControllerDelegate: NodeActionViewControllerGenericDelegate(
                viewController: navigationController,
                nodeActionListener: nodeActionListener(tracker)
            )
        )
        
        // this bridge is needed to do a searchBar <-> searchResults -> homeScreen communication without coupling this to
        // MEGA app level delegates. Using simple closures to pass data back and forth
        let searchBridge = SearchBridge(
            selection: { [weak sdk] result in
                bridge.hideKeyboard()
                router.didTapNode(result.id)
                // map from result id to a node to check if this is folder or a file
                if let node = sdk?.node(forHandle: result.id) {
                    let event = SearchItemSelectedEvent(
                        searchItemType: node.isFolder() ? .folder : .file
                    )
                    tracker.trackAnalyticsEvent(with: event)
                }
            },
            context: { result, button in
                let event = SearchResultOverflowMenuItemEvent()
                tracker.trackAnalyticsEvent(with: event)
                
                // button reference is required to position popover on the iPad correctly
                router.didTapMoreAction(on: result.id, button: button)
            },
            resignKeyboard: {
                bridge.hideKeyboard()
            },
            chipTapped: { chip, selected in
                tracker.trackChip(tapped: chip, selected: selected)
            }
        )
        
        bridge.didInputTextTrampoline = { [weak searchBridge] text in
            searchBridge?.queryChanged(text)
        }
        
        bridge.didClearTrampoline = { [weak searchBridge] in
            searchBridge?.queryCleaned()
        }
        
        bridge.didFinishSearchingTrampoline = { [weak searchBridge] in
            searchBridge?.searchCancelled()
        }
        
        bridge.updateBottomInsetTrampoline = { [weak searchBridge] inset in
            searchBridge?.updateBottomInset(inset)
        }
        
        let vm = SearchResultsViewModel(
            resultsProvider: HomeSearchResultsProvider(
                searchFileUseCase: makeSearchFileUseCase(),
                nodeDetailUseCase: makeNodeDetailUseCase(),
                nodeRepository: makeNodeRepo()
            ),
            bridge: searchBridge,
            config: .searchConfig,
            keyboardVisibilityHandler: KeyboardVisibiltyHandler(notificationCenter: .default)
        )
        return UIHostingController(rootView: SearchResultsView(viewModel: vm))
    }
    
    private func makeNodeDetailUseCase() -> some NodeDetailUseCaseProtocol {
        NodeDetailUseCase(
            sdkNodeClient: .live,
            nodeThumbnailHomeUseCase: NodeThumbnailHomeUseCase(
                sdkNodeClient: .live,
                fileSystemClient: .live,
                thumbnailRepo: ThumbnailRepository.newRepo
            )
        )
    }
    
    private func makeSearchFileUseCase() -> some SearchFileUseCaseProtocol {
        SearchFileUseCase(
            nodeSearchClient: .live,
            searchFileHistoryUseCase: SearchFileHistoryUseCase(
                fileSearchHistoryRepository: .live
            )
        )
    }
    
    private func makeLegacySearchResultsViewController(
        with navigationController: UINavigationController,
        bridge: SearchResultsBridge,
        tracker: some AnalyticsTracking
    ) -> UIViewController {
        let searchResultViewModel = HomeSearchResultViewModel(
            searchFileUseCase: makeSearchFileUseCase(),
            searchFileHistoryUseCase: SearchFileHistoryUseCase(
                fileSearchHistoryRepository: .live
            ),
            nodeDetailUseCase: makeNodeDetailUseCase(),
            router: HomeSearchResultRouter(
                navigationController: navigationController,
                nodeActionViewControllerDelegate: NodeActionViewControllerGenericDelegate(
                    viewController: navigationController,
                    nodeActionListener: nodeActionListener(tracker)
                )
            ),
            tracker: tracker,
            sdk: sdk
        )
        
        let homeSearchResultViewController = HomeSearchResultViewController()
        homeSearchResultViewController.viewModel = searchResultViewModel
        homeSearchResultViewController.resultTableViewDataSource
        = TableViewProxy<HomeSearchResultFileViewModel>(
            cellIdentifier: "SearchResultFile",
            emptyStateConfiguration: .searchResult,
            configureCell: { cell, model in
                (cell as? SearchResultFileTableViewCell)?.configure(with: model)
            },
            selectionAction: { selectedNode in
                searchResultViewModel.didSelectNode(selectedNode.handle)
            }
        )
        
        homeSearchResultViewController.hintTableViewDataSource = TableViewProxy<HomeSearchHintViewModel>(
            cellIdentifier: "SearchHint",
            emptyStateConfiguration: .searchHints,
            configureCell: { cell, model in
                (cell as? SearchHintTableViewCell)?.configure(with: model)
            },
            selectionAction: { selectedSearchHint in
                searchResultViewModel.didSelectHint(selectedSearchHint.text)
            }
        )
        // setting up the bridge connection instead of just connecting delegates
        homeSearchResultViewController.searchHintSelectDelegate = bridge
        
        bridge.didClearTrampoline = { [weak homeSearchResultViewController] in
            homeSearchResultViewController?.didClearText()
        }
        
        bridge.didInputTextTrampoline = { [weak homeSearchResultViewController] text in
            homeSearchResultViewController?.didInputText(text)
        }
        
        bridge.didHighlightTrampoline = { [weak homeSearchResultViewController] in
            homeSearchResultViewController?.didHighlightSearchBar()
        }
        
        return homeSearchResultViewController
    }
}
