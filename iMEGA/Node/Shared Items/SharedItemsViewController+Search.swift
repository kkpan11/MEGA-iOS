import MEGADomain

@objc final class TaskOCWrapper: NSObject {
    var task: Task<(), Never>?
}

extension SharedItemsViewController: UISearchBarDelegate {
    
    @objc func updateSearchResults(searchString: String, showsHUD: Bool = true) {
        if searchController.isActive {
            if searchString.count < kMinimumLettersToStartTheSearch {
                searchNodeUseCaseOCWrapper?.cancelSearch()
                cancelSearchTask()
                loadDefaultSharedItems()
            } else {
                if searchNodeUseCaseOCWrapper == nil {
                    searchNodeUseCaseOCWrapper = SearchNodeUseCaseOCWrapper()
                }
                
                search(by: searchString, showsHUD: showsHUD)
            }
        } else {
            searchNodeUseCaseOCWrapper?.cancelSearch()
        }
        reloadUI()
    }
    
    @objc func loadDefaultSharedItems() {
        if incomingButton?.isSelected ?? false {
            searchUnverifiedNodes(key: "")
            searchNodesArray = incomingNodesMutableArray
        } else if outgoingButton?.isSelected ?? false {
            searchUnverifiedNodes(key: "")
            searchNodesArray = outgoingNodesMutableArray
        } else if linksButton?.isSelected ?? false {
            searchUnverifiedNodesArray.removeAllObjects()
            if publicLinksArray.isNotEmpty, let publicLinksArray = (publicLinksArray as NSArray).mutableCopy() as? NSMutableArray {
                searchNodesArray = publicLinksArray
            }
        }
        tableView?.reloadData()
    }
    
    func evaluateSearchResult(searchText: String, sortType: MEGASortOrderType, showsHUD: Bool, asyncSearchClosure: @escaping (String, MEGASortOrderType) async throws -> [MEGANode]?) async {
        do {
            if showsHUD {
                SVProgressHUD.show()
            }
            if let nodes = try await asyncSearchClosure(searchText, sortType) {
                if Task.isCancelled { return }
                if let mutableNodeArray = (nodes as NSArray).mutableCopy() as? NSMutableArray {
                    searchNodesArray = mutableNodeArray
                }
            } else {
                if Task.isCancelled { return }
                searchNodesArray.removeAllObjects()
            }
            if showsHUD {
                await SVProgressHUD.dismiss()
            }
        } catch {
            if Task.isCancelled { return }
            if showsHUD {
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            }
        }
        self.tableView?.reloadData()
    }

    @objc func search(by searchText: String, showsHUD: Bool) {
        guard let searchNodeUseCaseOCWrapper else { return }
        if searchTask == nil {
            searchTask = .init()
        }
        
        cancelSearchTask()
        searchTask?.task = Task { @MainActor in
            if incomingButton?.isSelected ?? false {
                searchUnverifiedNodes(key: searchText)
                await evaluateSearchResult(searchText: searchText, sortType: sortOrderType, showsHUD: showsHUD, asyncSearchClosure: searchNodeUseCaseOCWrapper.searchOnInShares)
            } else if outgoingButton?.isSelected ?? false {
                searchUnverifiedNodes(key: searchText)
                await evaluateSearchResult(searchText: searchText, sortType: sortOrderType, showsHUD: showsHUD, asyncSearchClosure: searchNodeUseCaseOCWrapper.searchOnOutShares)
            } else if linksButton?.isSelected ?? false {
                searchUnverifiedNodesArray.removeAllObjects()
                await evaluateSearchResult(searchText: searchText, sortType: sortOrderType, showsHUD: showsHUD, asyncSearchClosure: searchNodeUseCaseOCWrapper.searchOnPublicLinks)
            }
        }
    }
    
    @objc func cancelSearchTask() {
        searchTask?.task?.cancel()
    }
    
    // MARK: - UISearchBarDelegate
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchNodesArray.removeAllObjects()
        searchUnverifiedNodesArray.removeAllObjects()
        searchUnverifiedSharesArray.removeAllObjects()
        
        searchNodeUseCaseOCWrapper?.cancelSearch()
        searchNodeUseCaseOCWrapper = nil
        
        loadDefaultSharedItems()
        
        if !MEGAReachabilityManager.isReachable() {
            self.tableView?.tableHeaderView = nil
        } else {
            configSearch()
        }
    }
}
