import MEGADomain
import MEGASdk

extension MEGARequestType {
    func toRequestTypeEntity() -> RequestTypeEntity {
        switch self {
        case .MEGARequestTypeLogin:
            return .login
        case .MEGARequestTypeCreateFolder:
            return .createFolder
        case .MEGARequestTypeMove:
            return .move
        case .MEGARequestTypeCopy:
            return .copy
        case .MEGARequestTypeRename:
            return .rename
        case .MEGARequestTypeRemove:
            return .remove
        case .MEGARequestTypeShare:
            return .share
        case .MEGARequestTypeImportLink:
            return .importLink
        case .MEGARequestTypeExport:
            return .export
        case .MEGARequestTypeFetchNodes:
            return .fetchNodes
        case .MEGARequestTypeAccountDetails:
            return .accountDetails
        case .MEGARequestTypeChangePassword:
            return .changePassword
        case .MEGARequestTypeUpload:
            return .upload
        case .MEGARequestTypeLogout:
            return .logout
        case .MEGARequestTypeGetPublicNode:
            return .getPublicNode
        case .MEGARequestTypeGetAttrFile:
            return .getAttrFile
        case .MEGARequestTypeSetAttrFile:
            return .setAttrFile
        case .MEGARequestTypeGetAttrUser:
            return .getAttrUser
        case .MEGARequestTypeSetAttrUser:
            return .setAttrUser
        case .MEGARequestTypeRetryPendingConnections:
            return .retryPendingConnections
        case .MEGARequestTypeRemoveContact:
            return .removeContact
        case .MEGARequestTypeCreateAccount:
            return .createAccount
        case .MEGARequestTypeConfirmAccount:
            return .confirmAccount
        case .MEGARequestTypeQuerySignUpLink:
            return .querySignUpLink
        case .MEGARequestTypeAddSync:
            return .addSync
        case .MEGARequestTypeRemoveSync:
            return .removeSync
        case .MEGARequestTypeDisableSync:
            return .disableSync
        case .MEGARequestTypeEnableSync:
            return .enableSync
        case .MEGARequestTypeCopySyncConfig:
            return .copySyncConfig
        case .MEGARequestTypeCopyCachedConfig:
            return .copyCachedConfig
        case .MEGARequestTypeImportSyncConfigs:
            return .importSyncConfigs
        case .MEGARequestTypeRemoveSyncs:
            return .removeSyncs
        case .MEGARequestTypePauseTransfers:
            return .pauseTransfers
        case .MEGARequestTypeCancelTransfer:
            return .cancelTransfer
        case .MEGARequestTypeCancelTransfers:
            return .cancelTransfers
        case .MEGARequestTypeDelete:
            return .delete
        case .MEGARequestTypeReportEvent:
            return .reportEvent
        case .MEGARequestTypeCancelAttrFile:
            return .cancelAttrFile
        case .MEGARequestTypeGetPricing:
            return .getPricing
        case .MEGARequestTypeGetPaymentId:
            return .getPaymentId
        case .MEGARequestTypeGetUserData:
            return .getUserData
        case .MEGARequestTypeLoadBalancing:
            return .loadBalancing
        case .MEGARequestTypeKillSession:
            return .killSession
        case .MEGARequestTypeSubmitFeedback:
            return .submitFeedback
        case .MEGARequestTypeSendEvent:
            return .sendEvent
        case .MEGARequestTypeCleanRubbishBin:
            return .cleanRubbishBin
        case .MEGARequestTypeGetRecoveryLink:
            return .getRecoveryLink
        case .MEGARequestTypeQueryRecoveryLink:
            return .queryRecoveryLink
        case .MEGARequestTypeConfirmRecoveryLink:
            return .confirmRecoveryLink
        case .MEGARequestTypeGetCancelLink:
            return .getCancelLink
        case .MEGARequestTypeConfirmCancelLink:
            return .confirmCancelLink
        case .MEGARequestTypeGetChangeEmailLink:
            return .getChangeEmailLink
        case .MEGARequestTypeConfirmChangeEmailLink:
            return .confirmChangeEmailLink
        case .MEGARequestTypeChatUpdatePermissions:
            return .chatUpdatePermissions
        case .MEGARequestTypeChatTruncate:
            return .chatTruncate
        case .MEGARequestTypeChatSetTitle:
            return .chatSetTitle
        case .MEGARequestTypeSetMaxConnections:
            return .setMaxConnections
        case .MEGARequestTypePauseTransfer:
            return .pauseTransfer
        case .MEGARequestTypeMoveTransfer:
            return .moveTransfer
        case .MEGARequestTypeChatPresenceUrl:
            return .chatPresenceUrl
        case .MEGARequestTypeRegisterPushNotification:
            return .registerPushNotification
        case .MEGARequestTypeGetUserEmail:
            return .getUserEmail
        case .MEGARequestTypeAppVersion:
            return .appVersion
        case .MEGARequestTypeGetLocalSSLCertificate:
            return .getLocalSSLCertificate
        case .MEGARequestTypeSendSignupLink:
            return .sendSignupLink
        case .MEGARequestTypeQueryDns:
            return .queryDns
        case .MEGARequestTypeQueryGelb:
            return .queryGelb
        case .MEGARequestTypeChatStats:
            return .chatStats
        case .MEGARequestTypeDownloadFile:
            return .downloadFile
        case .MEGARequestTypeQueryTransferQuota:
            return .queryTransferQuota
        case .MEGARequestTypePasswordLink:
            return .passwordLink
        case .MEGARequestTypeGetAchievements:
            return .getAchievements
        case .MEGARequestTypeRestore:
            return .restore
        case .MEGARequestTypeRemoveVersions:
            return .removeVersions
        case .MEGARequestTypeChatArchive:
            return .chatArchive
        case .MEGARequestTypeWhyAmIBlocked:
            return .whyAmIBlocked
        case .MEGARequestTypeContactLinkCreate:
            return .contactLinkCreate
        case .MEGARequestTypeContactLinkQuery:
            return .contactLinkQuery
        case .MEGARequestTypeContactLinkDelete:
            return .contactLinkDelete
        case .MEGARequestTypeFolderInfo:
            return .folderInfo
        case .MEGARequestTypeRichLink:
            return .richLink
        case .MEGARequestTypeKeepMeAlive:
            return .keepMeAlive
        case .MEGARequestTypeMultiFactorAuthCheck:
            return .multiFactorAuthCheck
        case .MEGARequestTypeMultiFactorAuthGet:
            return .multiFactorAuthGet
        case .MEGARequestTypeMultiFactorAuthSet:
            return .multiFactorAuthSet
        case .MEGARequestTypeAddBackup:
            return .addBackup
        case .MEGARequestTypeRemoveBackup:
            return .removeBackup
        case .MEGARequestTypeTimer:
            return .timer
        case .MEGARequestTypeAbortCurrentBackup:
            return .abortCurrentBackup
        case .MEGARequestTypeGetPSA:
            return .getPSA
        case .MEGARequestTypeFetchTimeZone:
            return .fetchTimeZone
        case .MEGARequestTypeUseralertAcknowledge:
            return .userAlertAcknowledge
        case .MEGARequestTypeChatLinkHandle:
            return .chatLinkHandle
        case .MEGARequestTypeChatLinkUrl:
            return .chatLinkUrl
        case .MEGARequestTypeSetPrivateMode:
            return .setPrivateMode
        case .MEGARequestTypeAutojoinPublicChat:
            return .autojoinPublicChat
        case .MEGARequestTypeCatchup:
            return .catchup
        case .MEGARequestTypePublicLinkInformation:
            return .publicLinkInformation
        case .MEGARequestTypeGetBackgroundUploadURL:
            return .getBackgroundUploadURL
        case .MEGARequestTypeCompleteBackgroundUpload:
            return .completeBackgroundUpload
        case .MEGARequestTypeCloudStorageUsed:
            return .cloudStorageUsed
        case .MEGARequestTypeSendSMSVerificationCode:
            return .sendSMSVerificationCode
        case .MEGARequestTypeCheckSMSVerificationCode:
            return .checkSMSVerificationCode
        case .MEGARequestTypeGetCountryCallingCodes:
            return .getCountryCallingCodes
        case .MEGARequestTypeVerifyCredentials:
            return .verifyCredentials
        case .MEGARequestTypeGetMiscFlags:
            return .getMiscFlags
        case .MEGARequestTypeResendVerificationEmail:
            return .resendVerificationEmail
        case .MEGARequestTypeSupportTicket:
            return .supportTicket
        case .MEGARequestTypeRetentionTime:
            return .retentionTime
        case .MEGARequestTypeResetSmsVerifiedNumber:
            return .resetSmsVerifiedNumber
        case .MEGARequestTypeSendDevCommand:
            return .sendDevCommand
        case .MEGARequestTypeGetBanners:
            return .getBanners
        case .MEGARequestTypeDismissBanner:
            return .dismissBanner
        case .MEGARequestTypeBackupPut:
            return .backupPut
        case .MEGARequestTypeBackupRemove:
            return .backupRemove
        case .MEGARequestTypeBackupPutHeartbeat:
            return .backupPutHeartbeat
        case .MEGARequestTypeBackupInfo:
            return .backupInfo
        case .MEGARequestTypeGetAttrNode:
            return .getAttrNode
        case .MEGARequestTypeLoadExternalDriveBackups:
            return .loadExternalDriveBackups
        case .MEGARequestTypeCloseExternalDriveBackups:
            return .closeExternalDriveBackups
        case .MEGARequestTypeGetDownloadUrls:
            return .getDownloadUrls
        case .MEGARequestTypeStartChatCall:
            return .startChatCall
        case .MEGARequestTypeJoinChatCall:
            return .joinChatCall
        case .MEGARequestTypeEndChatCall:
            return .endChatCall
        case .MEGARequestTypeGetFAUploadUrl:
            return .getFAUploadUrl
        case .MEGARequestTypeExecuteOnThread:
            return .executeOnThread
        case .MEGARequestTypeGetChatOptions:
            return .getChatOptions
        case .MEGARequestTypeGetRecentActions:
            return .getRecentActions
        case .MEGARequestTypeCheckRecoveryKey:
            return .checkRecoveryKey
        case .MEGARequestTypeSetMyBackups:
            return .setMyBackups
        case .MEGARequestTypePutSet:
            return .putSet
        case .MEGARequestTypeRemoveSet:
            return .removeSet
        case .MEGARequestTypeFetchSet:
            return .fetchSet
        case .MEGARequestTypePutSetElement:
            return .putSetElement
        case .MEGARequestTypeRemoveSetElement:
            return .removeSetElement
        case .MEGARequestTypeRemoveOldBackupNodes:
            return .removeOldBackupNodes
        case .MEGARequestTypeSetSyncRunstate:
            return .setSyncRunstate
        case .MEGARequestTypeAddUpdateScheduledMeeting:
            return .addUpdateScheduledMeeting
        case .MEGARequestTypeDelScheduledMeeting:
            return .delScheduledMeeting
        case .MEGARequestTypeFetchScheduledMeeting:
            return .fetchScheduledMeeting
        case .MEGARequestTypeFetchScheduledMeetingOccurrences:
            return .fetchScheduledMeetingOccurrences
        case .MEGARequestTypeOpenShareDialog:
            return .openShareDialog
        case .MEGARequestTypeUpgradeSecurity:
            return .upgradeSecurity
        case .MEGARequestTypePutSetElements:
            return .putSetElements
        case .MEGARequestTypeRemoveSetElements:
            return .removeSetElements
        case .MEGARequestTypeExportSet:
            return .exportSet
        case .MEGARequestTypeExportedSetElement:
            return .exportedSetElement
        case .MEGARequestTypeGetRecommenedProPlan:
            return .getRecommendedProPlan
        case .MEGARequestTypeSubmitPurchaseReceipt:
            return .submitPurchaseReceipt
        case .MEGARequestTypeCreditCardStore:
            return .creditCardStore
        case .MEGARequestTypeUpgradeAccount:
            return .upgradeAccount
        case .MEGARequestTypeCreditCardQuerySubscriptions:
            return .creditCardQuerySubscriptions
        case .MEGARequestTypeCreditCardCancelSubscriptions:
            return .creditCardCancelSubscriptions
        case .MEGARequestTypeGetSessionTransferUrl:
            return .getSessionTransferUrl
        case .MEGARequestTypeGetPaymentMethods:
            return .getPaymentMethods
        case .MEGARequestTypeInviteContact:
            return .inviteContact
        case .MEGARequestTypeReplyContactRequest:
            return .replyContactRequest
        case .MEGARequestTypeSetAttrNode:
            return .setAttrNode
        case .MEGARequestTypeChatCreate:
            return .chatCreate
        case .MEGARequestTypeChatFetch:
            return .chatFetch
        case .MEGARequestTypeChatInvite:
            return .chatInvite
        case .MEGARequestTypeChatRemove:
            return .chatRemove
        case .MEGARequestTypeChatUrl:
            return .chatUrl
        case .MEGARequestTypeChatGrantAccess:
            return .chatGrantAccess
        case .MEGARequestTypeChatRemoveAccess:
            return .chatRemoveAccess
        case .MEGARequestTypeUseHttpsOnly:
            return .useHttpsOnly
        case .MEGARequestTypeSetProxy:
            return .setProxy
        case .MEGARequestTypeGetNotifications:
            return .getNotifications
        case .TotalOfRequestTypes:
            return .totalOfRequestTypes
        default:
            return .unknown
        }
    }
}
