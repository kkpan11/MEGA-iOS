import Combine
@testable import MEGA
import MEGAAnalyticsiOS
import MEGADomain
import XCTest

final class ChatRoomLinkViewModelTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()

    func testIsMeetingLinkOn_onReceiveMeetingLinkNoneNil_meetingLinkShouldBeOn() {
        let chatLinkUseCase = MockChatLinkUseCase(link: "Meeting link")
        
        let sut = ChatRoomLinkViewModel(chatLinkUseCase: chatLinkUseCase)
        
        let exp = expectation(description: "Should receive meeting link update")
        sut.$isMeetingLinkOn
            .dropFirst()
            .sink { [weak self] _ in
                guard let self else { return }
                exp.fulfill()
                subscriptions.removeAll()
            }
            .store(in: &subscriptions)
        wait(for: [exp], timeout: 1)
        XCTAssertTrue(sut.isMeetingLinkOn)
    }
    
    func testIsMeetingLinkOn_onReceiveMeetingLinkNil_meetingLinkShouldBeOff() {
        let chatLinkUseCase = MockChatLinkUseCase(link: nil)

        let sut = ChatRoomLinkViewModel(chatLinkUseCase: chatLinkUseCase)
        
        let exp = expectation(description: "Should receive meeting link update")
        sut.$isMeetingLinkOn
            .dropFirst()
            .sink { [weak self] _ in
                guard let self else { return }
                exp.fulfill()
                subscriptions.removeAll()
            }
            .store(in: &subscriptions)
        wait(for: [exp], timeout: 1)
        XCTAssertFalse(sut.isMeetingLinkOn)
    }

    func testShareMeetingLinkTapped_onShareLinkTapped_shouldTrackEvent() {
        let tracker = MockTracker()
        let sut = ChatRoomLinkViewModel(tracker: tracker)
        
        sut.shareMeetingLinkTapped()
        
        tracker.assertTrackAnalyticsEventCalled(
            with: [
                ScheduledMeetingShareMeetingLinkButtonEvent()
            ]
        )
    }
}

final class MockMeetingInfoRouter: MeetingInfoRouting {
    var showSharedFiles_calledTimes = 0
    var showManageChatHistory_calledTimes = 0
    var showEnableKeyRotation_calledTimes = 0
    var closeMeetingInfoView_calledTimes = 0
    var showLeaveChatAlert_calledTimes = 0
    var showShareActivity_calledTimes = 0
    var showSendToChat_calledTimes = 0
    var showLinkCopied_calledTimes = 0
    var showParticipantDetails_calledTimes = 0
    var inviteParticipants_calledTimes = 0
    var showAllContactsAlreadyAddedAlert_calledTimes = 0
    var showNoAvailableContactsAlert_calledTimes = 0
    var editMeeting_calledTimes = 0
    var editMeetingPublisher = PassthroughSubject<ScheduledMeetingEntity, Never>()
    var didUpdatePeerPermissionResult: ChatRoomParticipantPrivilege?
    
    func showSharedFiles(for chatRoom: MEGADomain.ChatRoomEntity) {
        showSharedFiles_calledTimes += 1
    }
    
    func showManageChatHistory(for chatRoom: MEGADomain.ChatRoomEntity) {
        showManageChatHistory_calledTimes += 1
    }
    
    func showEnableKeyRotation(for chatRoom: MEGADomain.ChatRoomEntity) {
        showEnableKeyRotation_calledTimes += 1
    }
    
    func closeMeetingInfoView() {
        closeMeetingInfoView_calledTimes += 1
    }
    
    func showLeaveChatAlert(leaveAction: @escaping (() -> Void)) {
        showLeaveChatAlert_calledTimes += 1
    }
    
    func showShareActivity(_ link: String, title: String?, description: String?) {
        showShareActivity_calledTimes += 1
    }
    
    func showSendToChat(_ link: String) {
        showSendToChat_calledTimes += 1
    }
    
    func showLinkCopied() {
        showLinkCopied_calledTimes += 1
    }
    
    func showParticipantDetails(email: String, userHandle: MEGADomain.HandleEntity, chatRoom: MEGADomain.ChatRoomEntity, didUpdatePeerPermission: @escaping (ChatRoomParticipantPrivilege) -> Void) {
        showParticipantDetails_calledTimes += 1
        if let didUpdatePeerPermissionResult {
            didUpdatePeerPermission(didUpdatePeerPermissionResult)
        }
    }
    
    func inviteParticipants(withParticipantsAddingViewFactory participantsAddingViewFactory: ParticipantsAddingViewFactory, excludeParticipantsId: Set<HandleEntity>, selectedUsersHandler: @escaping (([HandleEntity]) -> Void)) {
        inviteParticipants_calledTimes += 1
    }
    
    func showAllContactsAlreadyAddedAlert(withParticipantsAddingViewFactory participantsAddingViewFactory: MEGA.ParticipantsAddingViewFactory) {
        showAllContactsAlreadyAddedAlert_calledTimes += 1
    }
    
    func showNoAvailableContactsAlert(withParticipantsAddingViewFactory participantsAddingViewFactory: MEGA.ParticipantsAddingViewFactory) {
        showNoAvailableContactsAlert_calledTimes += 1
    }
    
    func edit(meeting: ScheduledMeetingEntity) -> AnyPublisher<ScheduledMeetingEntity, Never> {
        editMeeting_calledTimes += 1
        return editMeetingPublisher.eraseToAnyPublisher()
    }
}
