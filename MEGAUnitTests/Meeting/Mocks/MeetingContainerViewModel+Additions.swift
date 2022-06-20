@testable import MEGA

extension MeetingContainerViewModel {
    
    convenience init(
        router: MeetingContainerRouting = MockMeetingContainerRouter(),
        chatRoom: ChatRoomEntity = ChatRoomEntity(),
        callUseCase: CallUseCaseProtocol = MockCallUseCase(call: CallEntity()),
        chatRoomUseCase: ChatRoomUseCaseProtocol = MockChatRoomUseCase(),
        callManagerUseCase: CallManagerUseCaseProtocol = MockCallManagerUseCase(),
        userUseCase: UserUseCaseProtocol = MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false),
        authUseCase: AuthUseCaseProtocol = MockAuthUseCase(isUserLoggedIn: true),
        noUserJoinedUseCase: MeetingNoUserJoinedUseCaseProtocol = MockMeetingNoUserJoinedUseCase(),
        isTesting: Bool = true
    ) {
        self.init(
            router: router,
            chatRoom: chatRoom,
            callUseCase: callUseCase,
            chatRoomUseCase: chatRoomUseCase,
            callManagerUseCase: callManagerUseCase,
            userUseCase: userUseCase,
            authUseCase: authUseCase,
            noUserJoinedUseCase: noUserJoinedUseCase
        )
    }
}
