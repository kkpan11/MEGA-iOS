import Foundation

protocol MiniPlayerActionsDelegate: class {
    func play(index: IndexPath)
    func showPlayer(node: MEGAHandle, filePath: String?)
    func showPlayer(filePath: String?)
}

final class MiniPlayerDelegate: NSObject, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate {
    private weak var delegate: MiniPlayerActionsDelegate?
    private let loopMode: Bool
    private let itemsNumber: Int
    private var lastContentOffset: CGPoint?
    
    init(delegate: MiniPlayerActionsDelegate, loopMode: Bool = false, itemsNumber: Int) {
        self.delegate = delegate
        self.loopMode = loopMode
        self.itemsNumber = itemsNumber
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        collectionView.bounds.size
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        lastContentOffset = scrollView.contentOffset
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let collectionView = scrollView as? UICollectionView,
              let lastContentOffset = lastContentOffset,
              let currentIndexPath = collectionView.indexPathForItem(at: CGPoint(x: scrollView.contentOffset.x + (scrollView.frame.width / 2), y: (scrollView.frame.height / 2))) else { return}
        
        let lastIndexPath = collectionView.indexPathForItem(at: lastContentOffset)
        
        if loopMode, currentIndexPath.row == itemsNumber {
            collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .centeredHorizontally, animated: false)
        } else if lastIndexPath != currentIndexPath || lastIndexPath == IndexPath(row: 0, section: 0) {
            delegate?.play(index: currentIndexPath)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? MiniPlayerItemCollectionViewCell else { return }
        if let node = cell.item?.node {
            delegate?.showPlayer(node: node, filePath: cell.item?.url.absoluteString)
        } else {
            delegate?.showPlayer(filePath: cell.item?.url.path)
        }
    }
}
