import WebKit

struct AdsWebViewCoordinatorViewModel {
    func shouldHandleAdsTap(
        currentDomain: String,
        targetDomain: String,
        navigationAction: WKNavigationAction
    ) -> Bool {
        
        guard navigationAction.navigationType != .linkActivated else {
            return true
        }
        
        guard currentDomain != targetDomain else {
            return false
        }
        
        guard let targetFrame = navigationAction.targetFrame else {
            return true
        }
        
        return !navigationAction.sourceFrame.isMainFrame && targetFrame.isMainFrame
    }

    func urlHost(url: URL?) -> String? {
        guard let url else { return nil }
        
        guard #available(iOS 16.0, *) else {
            return url.host
        }
        return url.host()
    }
}
