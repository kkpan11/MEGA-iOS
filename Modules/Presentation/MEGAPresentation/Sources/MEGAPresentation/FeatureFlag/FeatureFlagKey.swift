import MEGADomain

public enum FeatureFlagKey: FeatureFlagName, CaseIterable, Sendable {
    case albumPhotoCache = "Album and Photo Cache"
    case designToken = "MEGADesignToken"
    case videoRevamp = "Video Revamp"
    case notificationCenter = "NotificationCenter"
    case hiddenNodes =  "Hidden Nodes"
    case videoPlaylistSharing = "Video Playlist Sharing"
    case recentlyWatchedVideos = "Recently Watched Videos"
    case nodeDescription = "Node Description"
    case photosBrowser = "New Photos Browser"
    case chatEmptyStates = "Chat Empty States"
    case visualMediaSearch = "Search Albums and Photos"
    case addVideosToVideoPlaylist = "Add videos to video playlist"
    case reorderVideosInVideoPlaylistContent = "Reorder videos in video playlist content"
}
