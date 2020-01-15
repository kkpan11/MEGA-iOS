
import UIKit
import Photos

class PhotoGridViewDataSource: NSObject {
    let album: Album
    let collectionView: UICollectionView
    var selectedAssets: [PHAsset]
    typealias SelectionHandler = (PHAsset, IndexPath, CGSize, CGPoint) -> Void
    let selectionHandler: SelectionHandler
    
    init(album: Album,
         collectionView: UICollectionView,
         selectedAssets: [PHAsset],
         selectionHandler: @escaping SelectionHandler) {
        self.album = album
        self.collectionView = collectionView
        self.selectedAssets = selectedAssets
        self.selectionHandler = selectionHandler
    }
    
    func didSelect(asset: PHAsset, atIndexPath indexPath: IndexPath) {
        if let index = selectedAssets.firstIndex(of: asset) {
           remove(asset: asset, atIndex: index, selectedIndexPath: indexPath)
        } else {
            add(asset: asset, selectedIndexPath: indexPath)
        }
    }
    
    private func add(asset: PHAsset, selectedIndexPath: IndexPath) {
        updateCollectionCell(atIndexPath: selectedIndexPath, selectedIndex: selectedAssets.count)
        selectedAssets.append(asset)
    }
    
    private func remove(asset: PHAsset, atIndex index: Int, selectedIndexPath: IndexPath) {
        selectedAssets.remove(at: index)
        updateCollectionCell(atIndexPath: selectedIndexPath, selectedIndex: nil)

        (index..<selectedAssets.count).forEach { index in
            let toUpdatAsset = selectedAssets[index]
            if let visibleCells = collectionView.visibleCells as? [PhotoGridViewCell] {
                visibleCells.forEach { cell in
                    if let asset = cell.asset,
                        asset == toUpdatAsset {
                        cell.selectedIndex = index
                    }
                }
            }
        }
    }
    
    func updateCollectionCell(atIndexPath indexPath: IndexPath, selectedIndex: Int?) {
        let collectionCell = collectionView.cellForItem(at: indexPath) as! PhotoGridViewCell
        collectionCell.selectedIndex = selectedIndex
    }
}

extension PhotoGridViewDataSource: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return album.assetCount()
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoGridViewCell.reuseIdentifier,
                                                      for: indexPath) as! PhotoGridViewCell
        
        let asset = album.asset(atIndex: indexPath.item)
        cell.asset = asset
        cell.selectedIndex = selectedAssets.firstIndex(of: asset)
        
        cell.tapHandler = { [weak self] instance, size, point in
            self?.selectionHandler(asset, indexPath, size, point)
        }
        
        cell.durationString = (asset.mediaType == .video) ? asset.duration.displayString : nil
        return cell
    }
}



