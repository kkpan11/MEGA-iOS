import MEGADomain
import MEGAPresentation

public protocol VideoRevampRouting: Routing {
    func openMediaBrowser(for video: NodeEntity, allVideos: [NodeEntity])
    func openMoreOptions(for video: NodeEntity, sender: Any)
    func openVideoPlaylistContent(for videoPlaylistEntity: VideoPlaylistEntity)
    func openVideoPicker(completion: @escaping ([NodeEntity]) -> Void)
    func popScreen()
}
