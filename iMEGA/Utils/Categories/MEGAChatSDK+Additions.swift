import MEGADomain
extension MEGAChatSdk {
    var firstActiveCall: MEGAChatCall? {
        guard let callIds = chatCallsIds() else { return nil }
        let calls = (0..<callIds.size)
            .compactMap { chatCall(forCallId: callIds.megaHandle(at: $0)) }
        return calls.first { $0.isActiveCall }
    }
    
    @objc var mnz_existsActiveCall: Bool {
        return firstActiveCall != nil
    }
    
    func isCallActive(forChatRoomId chatRoomId: UInt64) -> Bool {
        guard let call = chatCall(forChatId: chatRoomId) else { return false }
        return call.isActiveCall
    }
    
    @objc func mnz_createChatRoom(userHandle: UInt64, completion: @escaping(_ chatRoom: MEGAChatRoom) -> Void) {
        let peerList = MEGAChatPeerList()
        peerList.addPeer(withHandle: userHandle, privilege: MEGAChatRoomPrivilege.standard.rawValue)
        let delegate = createChatDelegate { (chatRoom) in
            completion(chatRoom)
        }
        
        createChatGroup(false, peers: peerList, delegate: delegate)
    }
    
    @objc func mnz_createChatRoom(
        usersArray: [MEGAUser],
        title: String?,
        allowNonHostToAddParticipants: Bool,
        completion: @escaping(_ chatRoom: MEGAChatRoom) -> Void
    ) {
        let peerList = MEGAChatPeerList.mnz_standardPrivilegePeerList(usersArray: usersArray)
        let delegate = createChatDelegate { (chatRoom) in
            completion(chatRoom)
        }
        
        createChatGroup(
            withPeers: peerList,
            title: title,
            speakRequest: false,
            waitingRoom: false,
            openInvite: allowNonHostToAddParticipants,
            delegate: delegate
        )
    }
    
    @objc func recentChats(max: Int) -> [MEGAChatListItem] {
        var recentChats = [MEGAChatListItem]()
        
        guard let chatListItems = self.chatListItems else {
            return recentChats
        }
        
        for i in 0..<chatListItems.size {
            guard let chatListItem = chatListItems.chatListItem(at: i) else {
                continue
            }
            if chatListItem.ownPrivilege.rawValue >= MEGAChatRoomPrivilege.standard.rawValue {
                recentChats.append(chatListItem)
            }
            
        }
        
        recentChats.sort { (a, b) -> Bool in
            let aDate = a.lastMessageDate ?? Date(timeIntervalSince1970: 0)
            let bDate = b.lastMessageDate ?? Date(timeIntervalSince1970: 0)
            return aDate.compare(bDate) == ComparisonResult.orderedDescending
        }
        
        return [MEGAChatListItem](recentChats[0..<min(max, recentChats.count)])
    }
    
    @objc func removeMEGAChatRequestDelegateAsync(_ delegate: any MEGAChatRequestDelegate) {
        Task.detached {
            MEGAChatSdk.shared.remove(delegate)
        }
    }
    
    @objc func removeMEGAChatDelegateAsync(_ delegate: MEGAChatDelegate) {
        Task.detached {
            MEGAChatSdk.shared.remove(delegate)
        }
    }
    
    @objc func removeMEGACallDelegateAsync(_ delegate: any MEGAChatCallDelegate) {
        Task.detached {
            MEGAChatSdk.shared.remove(delegate)
        }
    }
    
    func chatNode(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity) -> MEGANode? {
        if let message = self.message(forChat: chatId, messageId: messageId), let node = message.nodeList?.node(at: 0), handle == node.handle {
            return node
        } else if let messageForNodeHistory = self.messageFromNodeHistory(forChat: chatId, messageId: messageId), let node = messageForNodeHistory.nodeList?.node(at: 0), handle == node.handle {
            return node
        } else {
            return nil
        }
    }
    
    // MARK: - Private
    
    private func createChatDelegate(completion: @escaping(_ chatRoom: MEGAChatRoom) -> Void) -> MEGAChatGenericRequestDelegate {
        let delegate = MEGAChatGenericRequestDelegate { (request, error) in
            if error.type.rawValue == MEGAChatErrorType.MEGAChatErrorTypeOk.rawValue {
                guard let chatRoom = self.chatRoom(forChatId: request.chatHandle) else {
                    MEGALogError("Error when getting the newly created chat room with chat handle: \(request.chatHandle)")
                    return
                }
                completion(chatRoom)
            } else {
                MEGALogError("Error when creating the chat room: \(error)")
            }
        }
        
        return delegate
    }
}
