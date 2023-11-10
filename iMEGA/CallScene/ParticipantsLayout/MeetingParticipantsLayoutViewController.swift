import Combine
import Foundation
import MEGADomain
import MEGAL10n
import MEGAPresentation

final class MeetingParticipantsLayoutViewController: UIViewController, ViewType {
    private enum Constants {
        static let notificationMessageWhiteBackgroundColor = UIColor(white: 1.0, alpha: 0.95)
        static let notificationMessageWhiteTextColor = UIColor.white
        static let notificationMessageBlackTextColor = UIColor.black
    }
    
    @IBOutlet private weak var callCollectionView: CallCollectionView!
    @IBOutlet private weak var localUserView: LocalUserView!
    
    @IBOutlet private weak var speakerAvatarImageView: UIImageView!
    @IBOutlet private weak var speakerRemoteVideoImageView: UIImageView!
    @IBOutlet private weak var speakerMicImageView: UIImageView!
    @IBOutlet private weak var speakerNameLabel: UILabel!
    @IBOutlet private var speakerViews: Array<UIView>!
    @IBOutlet private weak var pageControl: UIPageControl!
    @IBOutlet private weak var stackViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var stackViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var stackViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var stackViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var callCollectionViewSpeakerModeHeight: NSLayoutConstraint!
    
    private var reconnectingNotificationView: CallNotificationView?
    private var poorConnectionNotificationView: CallNotificationView?
    private var waitingForOthersNotificationView: CallNotificationView?
    private var callEndTimerNotificationView: CallNotificationView?

    // MARK: - Internal properties
    private let viewModel: MeetingParticipantsLayoutViewModel
    private var titleView: CallTitleView
    lazy private var layoutModeBarButton = UIBarButtonItem(image: UIImage(resource: .speakerView),
                                               style: .plain,
                                               target: self,
                                               action: #selector(MeetingParticipantsLayoutViewController.didTapLayoutModeButton))
    lazy private var optionsMenuButton = UIBarButtonItem(image: UIImage(resource: .moreGrid),
                                                     style: .plain,
                                                     target: self,
                                                     action: #selector(MeetingParticipantsLayoutViewController.didTapOptionsButton))
    
    private var statusBarHidden = false {
      didSet(newValue) {
        setNeedsStatusBarAppearanceUpdate()
      }
    }
    
    private var isUserAGuest: Bool?
    private var emptyMeetingMessageView: EmptyMeetingMessageView?
    private var subscriptions = Set<AnyCancellable>()
    
    init(viewModel: MeetingParticipantsLayoutViewModel) {
        self.viewModel = viewModel
        self.titleView = CallTitleView.instanceFromNib
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        stackViewTopConstraint.constant = UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0
        stackViewBottomConstraint.constant = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
        
        navigationController?.navigationBar.isTranslucent = true
        overrideUserInterfaceStyle = .dark
        
        viewModel.invokeCommand = { [weak self] in
            self?.executeCommand($0)
        }
        
        navigationItem.titleView = titleView
        
        viewModel.dispatch(.onViewLoaded)
        
        bindToSubscriptions()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.dispatch(.onViewReady)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self] _ in
            guard let self else { return }
            callCollectionView.collectionViewLayout.invalidateLayout()
            localUserView.repositionView()
            emptyMeetingMessageView?.invalidateIntrinsicContentSize()
            viewModel.dispatch(.orientationOrModeChange(isIPhoneLandscape: UIDevice.current.iPhoneDevice && UIDevice.current.orientation.isLandscape, isSpeakerMode: callCollectionView.layoutMode == .speaker))
            viewModel.dispatch(.onOrientationChanged)
        })
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            forceDarkNavigationUI()
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        statusBarHidden
    }
    
    private func bindToSubscriptions() {
        // When answering with device locked and opening MEGA from CallKit, onViewDidAppear is not called, so it is needed to notify viewModel about view had appeared.
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                callCollectionView.reloadData()
                viewModel.dispatch(.onViewReady)
            }
            .store(in: &subscriptions)
    }
    
    // MARK: - Execute command
    @MainActor
    func executeCommand(_ command: MeetingParticipantsLayoutViewModel.Command) {
        switch command {
        case .configView(let title, let subtitle, let isUserAGuest, let isOneToOne):
            self.isUserAGuest = isUserAGuest
            configureNavigationBar(title, subtitle)
            callCollectionView.configure(with: self)
            if isOneToOne {
                navigationItem.rightBarButtonItems = nil
            }
            configureLayout(mode: .grid, participantsCount: 0)
        case .configLocalUserView(let position):
            localUserView.configure(for: position)
        case .switchMenusVisibility:
            statusBarHidden.toggle()
            navigationController?.setNavigationBarHidden(!(navigationController?.navigationBar.isHidden ?? false), animated: true)
            localUserView.updateOffsetWithNavigation(hidden: statusBarHidden)
            forceDarkNavigationUI()
        case .switchLayoutMode(let layoutMode, let participantsCount):
            configureLayout(mode: layoutMode, participantsCount: participantsCount)
        case .disableSwitchLayoutModeButton(let disable):
            disableSwitchLayoutModeButton(disable)
        case .switchLocalVideo(let isVideoEnabled):
            localUserView.switchVideo(to: isVideoEnabled)
        case .updateName(let name):
            titleView.configure(title: name, subtitle: nil)
        case .updateDuration(let duration):
            titleView.configure(title: nil, subtitle: duration)
        case .updatePageControl(let count):
            updateNumberOfPageControl(for: count)
        case .updateParticipants(let participants):
            callCollectionView.update(participants: participants)
        case .reloadParticipantAt(let index, let participants):
            callCollectionView.reloadParticipant(in: participants, at: index)
        case .updateSpeakerViewFor(let participant):
            updateSpeaker(participant)
        case .localVideoFrame(let width, let height, let buffer):
            localUserView.frameData(width: width, height: height, buffer: buffer)
        case .participantsStatusChanged(let addedParticipantCount,
                                        let removedParticipantCount,
                                        let addedParticipantNames,
                                        let removedParticipantNames,
                                        let isOnlyMyselfRemainingInTheCall):
            participantsStatusChanged(addedParticipantsCount: addedParticipantCount,
                                      removedParticipantsCount: removedParticipantCount,
                                      addedParticipantsNames: addedParticipantNames,
                                      removedParticipantsNames: removedParticipantNames) { [weak self] in
                if isOnlyMyselfRemainingInTheCall {
                    self?.viewModel.dispatch(.didEndDisplayLastPeerLeftStatusMessage)
                }
            }
        case .reconnecting:
            showReconnectingNotification()
            addParticipantsBlurEffect()
        case .reconnected:
            removeReconnectingNotification()
            removeParticipantsBlurEffect()
            showNotification(message: Strings.Localizable.online, backgroundColor: UIColor.systemGreen, textColor: Constants.notificationMessageWhiteTextColor)
        case .updateCameraPositionTo(let position):
            localUserView.addBlurEffect()
            localUserView.transformLocalVideo(for: position)
        case .updatedCameraPosition:
            localUserView.removeBlurEffect()
        case .showRenameAlert(let title, let isMeeting):
            showRenameAlert(title: title, isMeeting: isMeeting)
        case .enableRenameButton(let enabled):
            guard let renameAlertController = presentedViewController as? UIAlertController, let enableButton = renameAlertController.actions.last else {
                return
            }
            enableButton.isEnabled = enabled
        case .showNoOneElseHereMessage:
            showNoOneElseHereMessageView()
        case .showWaitingForOthersMessage:
            showWaitingForOthersMessageView()
        case .hideEmptyRoomMessage:
            removeEmptyRoomMessageViewIfNeeded()
            removeWaitingForOthersMessageViewIfNeeded()
        case .updateHasLocalAudio(let audio):
            localUserView.localAudio(enabled: audio)
        case .shouldHideSpeakerView(let hidden):
            speakerViews.forEach { $0.isHidden = hidden }
        case .ownPrivilegeChangedToModerator:
            showNotification(message: Strings.Localizable.Meetings.Notifications.moderatorPrivilege,
                             backgroundColor: Constants.notificationMessageWhiteBackgroundColor,
                             textColor: Constants.notificationMessageBlackTextColor)
        case .showBadNetworkQuality:
            if reconnectingNotificationView == nil {
                showPoorConnectionNotification()
            }
        case .hideBadNetworkQuality:
            removePoorConnectionNotification()
        case .updateAvatar(let image, let participant):
            callCollectionView.updateAvatar(image: image, for: participant)
        case .updateSpeakerAvatar(let image):
            speakerAvatarImageView.image = image
        case .updateMyAvatar(let image):
            localUserView.updateAvatar(image: image)
        case .updateCallEndDurationRemainingString(let durationRemainingString):
            updateCallEndDurationRemaining(string: durationRemainingString)
        case .removeCallEndDurationView:
            removeCallEndDurationView()
        case .configureSpeakerView(let isSpeakerMode, let constraintValue):
            callCollectionViewSpeakerModeHeight.isActive = isSpeakerMode
            configureLeadingAndTrailingConstraint(to: constraintValue)
        }
    }
    
    // MARK: - UI Actions
    @objc func didTapBackButton() {
        viewModel.dispatch(.tapOnBackButton)
    }

    @objc func didTapLayoutModeButton() {
        viewModel.dispatch(.tapOnLayoutModeButton)
    }
    
    @objc func didTapOptionsButton() {
        viewModel.dispatch(.tapOnOptionsMenuButton(presenter: navigationController ?? self, sender: optionsMenuButton))
    }
    
    @IBAction func didTapBackgroundView(_ sender: UITapGestureRecognizer) {
        guard view?.hitTest(sender.location(in: view), with: nil) != localUserView else {
            return
        }
        
        let yPosition = sender.location(in: callCollectionView).y
        viewModel.dispatch(.tapOnView(onParticipantsView: yPosition > 0 && yPosition < callCollectionView.frame.height))
    }
    
    // MARK: - Private
    
    private func configureLayout(mode: ParticipantsLayoutMode, participantsCount: Int) {
        layoutModeBarButton.image = mode == .speaker ? UIImage(resource: .galleryView) : UIImage(resource: .speakerView)
        viewModel.dispatch(.orientationOrModeChange(isIPhoneLandscape: UIDevice.current.iPhoneDevice && UIDevice.current.orientation.isLandscape, isSpeakerMode: mode == .speaker))
        speakerViews.forEach { $0.isHidden = mode == .grid || participantsCount == 0 }
        pageControl.isHidden = mode == .speaker || participantsCount <= 6
        callCollectionView.changeLayoutMode(mode)
    }
    
    private func disableSwitchLayoutModeButton(_ disable: Bool) {
        layoutModeBarButton.isEnabled = !disable
    }
    
    private func updateSpeaker(_ participant: CallParticipantEntity) {
        participant.speakerVideoDataDelegate = self
        viewModel.dispatch(.fetchSpeakerAvatar)
        speakerRemoteVideoImageView.isHidden = participant.video != .on
        if participant.hasScreenShare {
            speakerMicImageView.isHidden = true
            speakerNameLabel.text = Strings.Localizable.Calls.ScreenShare.MainView.presentingLabel(participant.name ?? "")
        } else {
            if participant.audio == .on && !participant.audioDetected {
                speakerMicImageView.isHidden = true
            } else {
                speakerMicImageView.isHidden = false
                speakerMicImageView.image = participant.audioDetected ? .micActive : .micMuted
            }
            speakerNameLabel.text = participant.name
        }
    }
    
    private func showNotification(message: String, backgroundColor: UIColor, textColor: UIColor, completion: (() -> Void)? = nil) {
        let notification = CallNotificationView.instanceFromNib
        view.addSubview(notification)
        notification.show(message: message, backgroundColor: backgroundColor, textColor: textColor, autoFadeOut: true, completion: completion)
    }
    
    private func updateNumberOfPageControl(for participantsCount: Int) {
        pageControl.numberOfPages = Int(ceil(Double(participantsCount) / 6.0))
        if pageControl.isHidden && participantsCount > 6 {
            pageControl.isHidden = false
            callCollectionView.reloadData()
        } else if !pageControl.isHidden && participantsCount <= 6 {
            pageControl.isHidden = true
            callCollectionView.reloadData()
        }
    }
    
    private func updateCallEndDurationRemaining(string: String) {
        let displayString = Strings.Localizable.Meetings.Notification.endCallTimerDuration(string)
                
        guard let notification = callEndTimerNotificationView else {
            let notification = CallNotificationView.instanceFromNib
            view.addSubview(notification)

            notification.show(message: displayString,
                              backgroundColor: Constants.notificationMessageWhiteBackgroundColor,
                              textColor: Constants.notificationMessageBlackTextColor)
            callEndTimerNotificationView = notification
            return
        }
        
        notification.updateMessage(string: displayString)
    }
    
    private func removeCallEndDurationView() {
        callEndTimerNotificationView?.removeFromSuperview()
        callEndTimerNotificationView = nil
    }
    
    func showRenameAlert(title: String, isMeeting: Bool) {
        let actionTitle = isMeeting ? Strings.Localizable.Meetings.Action.rename : Strings.Localizable.renameGroup
        let renameAlertController = UIAlertController(title: actionTitle, message: Strings.Localizable.renameNodeMessage, preferredStyle: .alert)

        renameAlertController.addTextField { textField in
            textField.text = title
            textField.returnKeyType = .done
            textField.enablesReturnKeyAutomatically = true
            textField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)
        }

        renameAlertController.addAction(UIAlertAction(title: Strings.Localizable.cancel, style: .cancel, handler: { [weak self] _ in
            self?.viewModel.dispatch(.discardChangeTitle)
        }))
        renameAlertController.addAction(UIAlertAction(title: Strings.Localizable.rename, style: .default, handler: { [weak self] _ in
            guard let newTitle = renameAlertController.textFields?.first?.text else {
                return
            }
            self?.viewModel.dispatch(.setNewTitle(newTitle))
        }))
        renameAlertController.actions.last?.isEnabled = false
        
        present(renameAlertController, animated: true, completion: nil)
    }

    @objc func textFieldDidChange(_ textField: UITextField) {
        guard let text = textField.text else {
            return
        }
        viewModel.dispatch(.renameTitleDidChange(text))
    }

    private func forceDarkNavigationUI() {
        guard let navigationBar = navigationController?.navigationBar else { return }
        AppearanceManager.forceNavigationBarUpdate(navigationBar, traitCollection: traitCollection)
    }
    
    private func configureNavigationBar(_ title: String, _ subtitle: String) {
        titleView.configure(title: title, subtitle: subtitle)
        if !(isUserAGuest ?? false) {
            navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(resource: .backArrow), style: .plain, target: self, action: #selector(self.didTapBackButton))
        }
        navigationItem.rightBarButtonItems = [optionsMenuButton,
                                              layoutModeBarButton]
    }
    
    private func showReconnectingNotification() {
        let notification = CallNotificationView.instanceFromNib
        view.addSubview(notification)
        notification.show(message: Strings.Localizable.Meetings.Reconnecting.title,
                          backgroundColor: .clear,
                          textColor: Constants.notificationMessageWhiteTextColor,
                          autoFadeOut: false,
                          blinking: true)
        reconnectingNotificationView = notification
    }
    
    private func removeReconnectingNotification() {
        guard let notification = reconnectingNotificationView else { return }
        notification.removeFromSuperview()
        reconnectingNotificationView = nil
    }
    
    private func showPoorConnectionNotification() {
        let notification = CallNotificationView.instanceFromNib
        view.addSubview(notification)
        notification.show(message: Strings.Localizable.Meetings.poorConnection,
                          backgroundColor: .clear,
                          textColor: Constants.notificationMessageWhiteTextColor,
                          autoFadeOut: false)
        poorConnectionNotificationView = notification
    }
    
    private func removePoorConnectionNotification() {
        guard let notification = poorConnectionNotificationView else { return }
        notification.removeFromSuperview()
        poorConnectionNotificationView = nil
    }
    
    private func addParticipantsBlurEffect() {
        callCollectionView.addBlurEffect()
    }
    
    private func removeParticipantsBlurEffect() {
        callCollectionView.removeBlurEffect()
    }
    
    private func showWaitingForOthersMessageView() {
        guard waitingForOthersNotificationView == nil else { return }
        
        let notification = CallNotificationView.instanceFromNib
        view.addSubview(notification)
        notification.show(
            message: Strings.Localizable.Meetings.Message.waitingOthers,
            backgroundColor: Constants.notificationMessageWhiteBackgroundColor,
            textColor: Constants.notificationMessageBlackTextColor
        )
        waitingForOthersNotificationView = notification
    }
    
    private func removeWaitingForOthersMessageViewIfNeeded() {
        guard let waitingForOthersNotificationView = waitingForOthersNotificationView else { return }
        waitingForOthersNotificationView.removeFromSuperview()
        self.waitingForOthersNotificationView = nil
    }
    
    private func showNoOneElseHereMessageView() {
        let emptyMessage = EmptyMeetingMessageView.instanceFromNib
        emptyMessage.translatesAutoresizingMaskIntoConstraints = false
        emptyMessage.messageLabel.text = Strings.Localizable.Meetings.Message.noOtherParticipants
        view.addSubview(emptyMessage)
        
        emptyMessage.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        emptyMessage.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true

        emptyMeetingMessageView = emptyMessage
    }
    
    private func removeEmptyRoomMessageViewIfNeeded() {
        guard let emptyMeetingMessageView = emptyMeetingMessageView else { return }
        emptyMeetingMessageView.removeFromSuperview()
        self.emptyMeetingMessageView = nil
    }
    
    private func participantsStatusChanged(addedParticipantsCount: Int,
                                           removedParticipantsCount: Int,
                                           addedParticipantsNames: [String]?,
                                           removedParticipantsNames: [String]?,
                                           completion: (() -> Void)?) {
        let addedMessage = notificationMessage(forParticipantCount: addedParticipantsCount,
                                               participantNames: addedParticipantsNames,
                                               oneParticipantMessageClosure: Strings.Localizable.Meetings.Notification.singleUserJoined,
                                               twoParticipantsMessageClousure: Strings.Localizable.Meetings.Notification.twoUsersJoined,
                                               moreThanTwoParticipantsMessageClousure: Strings.Localizable.Meetings.Notification.moreThanTwoUsersJoined)
        
        let removedMessage = notificationMessage(forParticipantCount: removedParticipantsCount,
                                                 participantNames: removedParticipantsNames,
                                                 oneParticipantMessageClosure: Strings.Localizable.Meetings.Notification.singleUserLeft,
                                                 twoParticipantsMessageClousure: Strings.Localizable.Meetings.Notification.twoUsersLeft,
                                                 moreThanTwoParticipantsMessageClousure: Strings.Localizable.Meetings.Notification.moreThanTwoUsersLeft)
        
        var message: String?
        if let addedMessage = addedMessage, let removedMessage = removedMessage {
            message = addedMessage + " " + removedMessage
        } else if let addedMessage = addedMessage {
            message = addedMessage
        } else if let removedMessage = removedMessage {
            message = removedMessage
        }
        
        if let message = message {
            showNotification(message: message,
                             backgroundColor: Constants.notificationMessageWhiteBackgroundColor,
                             textColor: Constants.notificationMessageBlackTextColor,
                             completion: completion)
        }
    }
    
    private func notificationMessage(forParticipantCount participantCount: Int,
                                     participantNames: [String]?,
                                     oneParticipantMessageClosure: (String) -> String,
                                     twoParticipantsMessageClousure: (String, String) -> String,
                                     moreThanTwoParticipantsMessageClousure: (String, String) -> String) -> String? {
        var message: String?
        
        if let participantNames = participantNames {
            switch participantCount {
            case 1 where participantNames.count == 1:
                message = oneParticipantMessageClosure(participantNames[0])
            case 2 where participantNames.count == 2:
                message = twoParticipantsMessageClousure(participantNames[0], participantNames[1])
            default:
                if participantCount > 2,
                   participantNames.count == 1 {
                    message = moreThanTwoParticipantsMessageClousure(participantNames[0], String(participantCount - 1))
                }
            }
        }
        
        return message
    }
    
    private func configureLeadingAndTrailingConstraint(to constant: CGFloat) {
        stackViewLeadingConstraint.constant = constant
        stackViewTrailingConstraint.constant = -constant
    }
}

// MARK: - CallParticipantVideoDelegate

extension MeetingParticipantsLayoutViewController: CallParticipantVideoDelegate {
    func videoFrameData(width: Int, height: Int, buffer: Data!, type: VideoFrameType) {
        speakerRemoteVideoImageView.image = UIImage.mnz_convert(toUIImage: buffer, withWidth: width, withHeight: height)
    }
}

extension MeetingParticipantsLayoutViewController: CallCollectionViewDelegate {
    func collectionViewDidChangeOffset(to page: Int, visibleIndexPaths: [IndexPath]) {
        pageControl.currentPage = page
        viewModel.dispatch(.indexVisibleParticipants(visibleIndexPaths.map { $0.item }))
    }
    
    func collectionViewDidSelectParticipant(participant: CallParticipantEntity, at indexPath: IndexPath) {
        viewModel.dispatch(.tapParticipantToPinAsSpeaker(participant))
    }
    
    func fetchAvatar(for participant: CallParticipantEntity) {
        viewModel.dispatch(.fetchAvatar(participant: participant))
    }
    
    func participantCellIsVisible(_ participant: CallParticipantEntity, at indexPath: IndexPath) {
        viewModel.dispatch(.participantIsVisible(participant, index: indexPath.item))
    }
}
