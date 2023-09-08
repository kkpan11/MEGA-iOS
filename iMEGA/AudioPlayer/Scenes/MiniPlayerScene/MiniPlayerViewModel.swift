import Foundation
import MEGADomain
import MEGAFoundation
import MEGAPresentation

enum MiniPlayerAction: ActionType {
    case onViewDidLoad
    case onPlayPause
    case playItem(AudioPlayerItem)
    case onClose
    case `deinit`
    case showPlayer(MEGANode?, String?)
}

protocol MiniPlayerViewRouting: Routing {
    func dismiss()
    func showPlayer(node: MEGANode?, filePath: String?)
    func isAFolderLinkPresenter() -> Bool
}

final class MiniPlayerViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
        case reloadNodeInfo(thumbnail: UIImage?)
        case reloadPlayerStatus(percentage: Float, isPlaying: Bool)
        case initTracks(currentItem: AudioPlayerItem, queue: [AudioPlayerItem]?, loopMode: Bool)
        case change(currentItem: AudioPlayerItem, indexPath: IndexPath)
        case reload(currentItem: AudioPlayerItem)
        case showLoading(_ show: Bool)
        case enableUserInteraction(_ enable: Bool)
    }
    
    // MARK: - Private properties
    private var configEntity: AudioPlayerConfigEntity
    private var shouldInitializePlayer: Bool = false
    private let router: any MiniPlayerViewRouting
    private let nodeInfoUseCase: (any NodeInfoUseCaseProtocol)?
    private let streamingInfoUseCase: (any StreamingInfoUseCaseProtocol)?
    private let offlineInfoUseCase: (any OfflineFileInfoUseCaseProtocol)?
    private let playbackContinuationUseCase: any PlaybackContinuationUseCaseProtocol
    private let dispatchQueue: any DispatchQueueProtocol
    
    // MARK: - Internal properties
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Init
    init(configEntity: AudioPlayerConfigEntity,
         router: some MiniPlayerViewRouting,
         nodeInfoUseCase: (any NodeInfoUseCaseProtocol)?,
         streamingInfoUseCase: (any StreamingInfoUseCaseProtocol)?,
         offlineInfoUseCase: (any OfflineFileInfoUseCaseProtocol)?,
         playbackContinuationUseCase: any PlaybackContinuationUseCaseProtocol,
         dispatchQueue: some DispatchQueueProtocol = DispatchQueue.global()) {
        self.configEntity = configEntity
        self.router = router
        self.nodeInfoUseCase = nodeInfoUseCase
        self.streamingInfoUseCase = streamingInfoUseCase
        self.offlineInfoUseCase = offlineInfoUseCase
        self.playbackContinuationUseCase = playbackContinuationUseCase
        self.dispatchQueue = dispatchQueue
        self.shouldInitializePlayer = configEntity.shouldResetPlayer
    }
    
    // MARK: - Dispatch action
    func dispatch(_ action: MiniPlayerAction) {
        switch action {
        case .onViewDidLoad:
            invokeCommand?(.showLoading(shouldInitializePlayer))
            determinePlayerSetupOnViewDidLoad()
        case .onPlayPause:
            configEntity.playerHandler.playerTogglePlay()
        case .playItem(let item):
            if configEntity.playerHandler.currentRepeatMode() == .repeatOne {
                configEntity.playerHandler.playerRepeatAll(active: true)
            }
            configEntity.playerHandler.play(item: item)
        case .onClose:
            closeMiniPlayer()
        case .deinit:
            deInitActions()
        case .showPlayer(let node, let filePath):
            showFullScreenPlayer(node, path: filePath)
        }
    }
    
    private func determinePlayerSetupOnViewDidLoad() {
        guard shouldInitializePlayer else {
            configurePlayer()
            return
        }
        
        dispatchQueue.async(qos: .userInteractive) { [weak self] in
            self?.preparePlayer()
        }
    }
    
    private func preparePlayer() {
        guard configEntity.playerType == .offline else {
            preparePlayerForNonOfflinePlayerType()
            return
        }
        preparePlayerForOfflinePlayerType()
    }
    
    private func preparePlayerForOfflinePlayerType() {
        guard let offlineFilePaths = configEntity.relatedFiles else {
            router.dismiss()
            return
        }
        
        guard
            let currentItem = configEntity.playerHandler.playerCurrentItem(),
            currentItem.url.path == configEntity.fileLink,
            currentItem.node == configEntity.node
        else {
            initialize(with: offlineFilePaths)
            return
        }
        configurePlayer()
        configEntity.playerHandler.resetCurrentItem()
    }
    
    private func preparePlayerForNonOfflinePlayerType() {
        guard let node = configEntity.node else {
            router.dismiss()
            return
        }
        
        if !(streamingInfoUseCase?.isLocalHTTPProxyServerRunning() ?? true) {
            streamingInfoUseCase?.startServer()
        }
        
        guard
            let currentItem = configEntity.playerHandler.playerCurrentItem(),
            currentItem.node == node
        else {
            initialize(with: node)
            return
        }
        configurePlayer()
        configEntity.playerHandler.resetCurrentItem()
    }
    
    private func configurePlayer() {
        configEntity.playerHandler.addPlayer(listener: self)
        
        guard !configEntity.playerHandler.isPlayerEmpty(), let currentItem = configEntity.playerHandler.playerCurrentItem() else {
            router.dismiss()
            return
        }
        invokeCommand?(.initTracks(currentItem: currentItem, queue: configEntity.playerHandler.playerPlaylistItems(), loopMode: configEntity.playerHandler.currentRepeatMode() == .loop))
        if let artworkImage = currentItem.artwork {
            invokeCommand?(.reloadNodeInfo(thumbnail: artworkImage))
        }
        
        configEntity.playerHandler.refreshCurrentItemState()
    }
    
    // MARK: - Node Init
    
    private func initialize(with node: MEGANode) {
        if configEntity.isFileLink {
            guard let track = streamingInfoUseCase?.info(from: node) else {
                router.dismiss()
                return
            }
            initialize(tracks: [track], currentTrack: track)
        } else {
            guard let children = configEntity.isFolderLink ? nodeInfoUseCase?.folderChildrenInfo(fromParentHandle: node.parentHandle) :
                                                nodeInfoUseCase?.childrenInfo(fromParentHandle: node.parentHandle),
                  let currentTrack = children.first(where: { $0.node?.handle == node.handle }) else {
                
                guard let track = streamingInfoUseCase?.info(from: node) else {
                    router.dismiss()
                    return
                }
                initialize(tracks: [track], currentTrack: track)
                return
            }
            initialize(tracks: children, currentTrack: currentTrack)
        }
    }
    
    // MARK: - Offline Files Init
    
    private func initialize(with offlineFilePaths: [String]) {
        guard
            let files = offlineInfoUseCase?.info(from: offlineFilePaths),
            let currentFilePath = configEntity.fileLink,
            let currentTrack = files.first(where: { $0.url.path == currentFilePath })
        else {
            router.dismiss()
            return
        }
        initialize(tracks: files, currentTrack: currentTrack)
    }
    
    // MARK: - Private functions
    
    private func initialize(tracks: [AudioPlayerItem], currentTrack: AudioPlayerItem) {
        let mutableTracks = shift(tracks: tracks, startItem: currentTrack)
        CrashlyticsLogger.log("[AudioPlayer] type: , \(configEntity.playerType)")
        resetConfigurationIfNeeded(nextCurrentTrack: currentTrack)
        configEntity.playerHandler.autoPlay(enable: configEntity.playerType != .fileLink)
        configEntity.playerHandler.addPlayer(tracks: mutableTracks)
        configurePlayer()
    }

    private func shift(tracks: [AudioPlayerItem], startItem: AudioPlayerItem) -> [AudioPlayerItem] {
        guard tracks.contains(startItem) else { return tracks }
        return tracks.shifted(tracks.firstIndex(of: startItem) ?? 0)
    }
    
    private func resetConfigurationIfNeeded(nextCurrentTrack: AudioPlayerItem) {
        switch configEntity.playerType {
        case .default:
            if let currentNode = configEntity.playerHandler.playerCurrentItem()?.node {
                guard let nextCurrentNode = nextCurrentTrack.node,
                      nextCurrentNode.parentHandle != currentNode.parentHandle else { return }
            }
            
        case .folderLink:
            guard !configEntity.playerHandler.playerTracksContains(url: nextCurrentTrack.url) else { return }
            
        case .offline:
            let nextCurrentItemDirectoryURL = nextCurrentTrack.url.deletingLastPathComponent()
            guard let currentItemDirectoryURL = configEntity.playerHandler.playerCurrentItem()?.url.deletingLastPathComponent(),
                  nextCurrentItemDirectoryURL != currentItemDirectoryURL else { return }
            
        default:
            break
        }
        
        configEntity.playerHandler.resetAudioPlayerConfiguration()
    }
    
    private func showFullScreenPlayer(_ node: MEGANode?, path: String?) {
        configEntity.playerHandler.removePlayer(listener: self)
        switch configEntity.playerType {
        case .`default`:
            return router.showPlayer(node: node, filePath: nil)
        case .folderLink, .fileLink, .offline:
            return router.showPlayer(node: node, filePath: configEntity.playerType == .fileLink ? configEntity.fileLink : path)
        }
    }
    
    private func closeMiniPlayer() {
        streamingInfoUseCase?.stopServer()
        if configEntity.isFolderLink, !router.isAFolderLinkPresenter() {
            nodeInfoUseCase?.folderLinkLogout()
        }
        router.dismiss()
    }
    
    private func deInitActions() {
        configEntity.playerHandler.removePlayer(listener: self)
        
        if configEntity.isFolderLink, !router.isAFolderLinkPresenter() {
            nodeInfoUseCase?.folderLinkLogout()
        }
    }
}

extension MiniPlayerViewModel: AudioPlayerObserversProtocol {
    func audio(player: AVQueuePlayer, showLoading: Bool) {
        invokeCommand?(.showLoading(showLoading))
    }
    
    func audio(player: AVQueuePlayer, currentTime: Double, remainingTime: Double, percentageCompleted: Float, isPlaying: Bool) {
        invokeCommand?(.reloadPlayerStatus(percentage: percentageCompleted, isPlaying: isPlaying))
    }
    
    func audio(player: AVQueuePlayer, currentItem: AudioPlayerItem?, currentThumbnail: UIImage?) {
        invokeCommand?(.reloadNodeInfo(thumbnail: currentThumbnail))
    }
    
    func audio(player: AVQueuePlayer, name: String, artist: String, thumbnail: UIImage?, url: String) {
        invokeCommand?(.reloadNodeInfo(thumbnail: thumbnail))
    }
    
    func audio(player: AVQueuePlayer, name: String, artist: String, thumbnail: UIImage?) {
        invokeCommand?(.reloadNodeInfo(thumbnail: thumbnail))
    }
    
    func audio(player: AVQueuePlayer, currentItem: AudioPlayerItem?, indexPath: IndexPath?) {
        guard let currentItem = currentItem, let indexPath = indexPath else { return }
        invokeCommand?(.change(currentItem: currentItem, indexPath: indexPath))
    }
    
    func audio(player: AVQueuePlayer, reload item: AudioPlayerItem?) {
        guard let currentItem = item else { return }
        invokeCommand?(.reload(currentItem: currentItem))
    }
    
    func audioPlayerWillStartBlockingAction() {
        invokeCommand?(.enableUserInteraction(false))
    }
    
    func audioPlayerDidFinishBlockingAction() {
        invokeCommand?(.enableUserInteraction(true))
    }
    
    func audioDidStartPlayingItem(_ item: AudioPlayerItem?) {
        guard let item, let fingerprint = item.node?.toNodeEntity().fingerprint else {
            return
        }
        
        switch playbackContinuationUseCase.status(for: fingerprint) {
        case .displayDialog(let playbackTime):
            playbackContinuationUseCase.setPreference(to: .resumePreviousSession)
            configEntity.playerHandler.playerResumePlayback(from: playbackTime)
        case .resumeSession(let playbackTime):
            configEntity.playerHandler.playerResumePlayback(from: playbackTime)
        case .startFromBeginning: break
        }
    }
}
