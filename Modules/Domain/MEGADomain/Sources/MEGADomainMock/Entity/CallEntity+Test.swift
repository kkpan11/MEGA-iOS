import Foundation
import MEGADomain

public extension CallEntity {
    /// Init method with default values (0, false, nil, [], ...)
    init(
        status: CallStatusType? = .inProgress,
        chatId: HandleEntity = 0,
        callId: HandleEntity = 0,
        changeType: ChangeType? = .noChanges,
        duration: Int64 = 0,
        initialTimestamp: Int64 = 0,
        finalTimestamp: Int64 = 0,
        callWillEndTimestamp: Int64 = 0,
        hasLocalAudio: Bool = false,
        hasLocalVideo: Bool = false,
        termCodeType: TermCodeType? = .invalid,
        callLimits: CallLimitsEntity = CallLimitsEntity(durationLimit: 0, maxUsers: 0, maxClientsPerUser: 0, maxClients: 0),
        callDurationLimit: Int = 0,
        isRinging: Bool = false,
        callCompositionChange: CompositionChangeType? = .noChange,
        numberOfParticipants: Int = 0,
        isOnHold: Bool = false,
        isOwnClientCaller: Bool = false,
        sessionClientIds: [HandleEntity] = [],
        clientSessions: [ChatSessionEntity] = [],
        participants: [HandleEntity] = [],
        waitingRoomStatus: WaitingRoomStatus = .unknown,
        waitingRoom: WaitingRoomEntity? = nil,
        waitingRoomHandleList: [HandleEntity] = [],
        raiseHandsList: [HandleEntity] = [],
        uuid: UUID = .testUUID,
        isTesting: Bool = true
    ) {
        self.init(
            status: status,
            chatId: chatId,
            callId: callId,
            changeType: changeType,
            duration: duration,
            initialTimestamp: initialTimestamp,
            finalTimestamp: finalTimestamp,
            callWillEndTimestamp: callWillEndTimestamp,
            hasLocalAudio: hasLocalAudio,
            hasLocalVideo: hasLocalVideo,
            termCodeType: termCodeType,
            callLimits: callLimits,
            isRinging: isRinging,
            callCompositionChange: callCompositionChange,
            numberOfParticipants: numberOfParticipants,
            isOnHold: isOnHold,
            isOwnClientCaller: isOwnClientCaller,
            sessionClientIds: sessionClientIds,
            clientSessions: clientSessions,
            participants: participants,
            waitingRoomStatus: waitingRoomStatus,
            waitingRoom: waitingRoom,
            waitingRoomHandleList: waitingRoomHandleList,
            raiseHandsList: raiseHandsList,
            uuid: uuid
        )
    }
    
    static func testEntity(
        status: CallStatusType? = .inProgress,
        chatId: HandleEntity = 0,
        callId: HandleEntity = 0,
        changeType: ChangeType? = .noChanges,
        duration: Int64 = 0,
        initialTimestamp: Int64 = 0,
        finalTimestamp: Int64 = 0,
        callWillEndTimestamp: Int64 = 0,
        hasLocalAudio: Bool = false,
        hasLocalVideo: Bool = false,
        termCodeType: TermCodeType? = .invalid,
        callLimits: CallLimitsEntity = CallLimitsEntity(durationLimit: 0, maxUsers: 0, maxClientsPerUser: 0, maxClients: 0),
        callDurationLimit: Int = 0,
        isRinging: Bool = false,
        callCompositionChange: CompositionChangeType? = .noChange,
        numberOfParticipants: Int = 0,
        isOnHold: Bool = false,
        isOwnClientCaller: Bool = false,
        sessionClientIds: [HandleEntity] = [],
        clientSessions: [ChatSessionEntity] = [],
        participants: [HandleEntity] = [],
        waitingRoomStatus: WaitingRoomStatus = .unknown,
        waitingRoom: WaitingRoomEntity? = nil,
        waitingRoomHandleList: [HandleEntity] = [],
        raiseHandsList: [HandleEntity] = [],
        uuid: UUID = .testUUID
    ) -> Self {
        .init(
            status: status,
            chatId: chatId,
            callId: callId,
            changeType: changeType,
            duration: duration,
            initialTimestamp: initialTimestamp,
            finalTimestamp: finalTimestamp,
            callWillEndTimestamp: callWillEndTimestamp,
            hasLocalAudio: hasLocalAudio,
            hasLocalVideo: hasLocalVideo,
            termCodeType: termCodeType,
            callLimits: callLimits,
            isRinging: isRinging,
            callCompositionChange: callCompositionChange,
            numberOfParticipants: numberOfParticipants,
            isOnHold: isOnHold,
            isOwnClientCaller: isOwnClientCaller,
            sessionClientIds: sessionClientIds,
            clientSessions: clientSessions,
            participants: participants,
            waitingRoomStatus: waitingRoomStatus,
            waitingRoom: waitingRoom,
            waitingRoomHandleList: waitingRoomHandleList,
            raiseHandsList: raiseHandsList,
            uuid: uuid
        )
    }
}

public extension UUID {
    static var testUUID = UUID(uuidString: "45adcd56-a31c-11eb-bcbc-0242ac130002")!
}
