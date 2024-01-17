import MEGADomain

public struct MockAccountUseCase: AccountUseCaseProtocol {
    private let totalNodesCountVariable: UInt64
    private let getMyChatFilesFolderResult: (Result<NodeEntity, AccountErrorEntity>)
    private let accountDetailsResult: (Result<AccountDetailsEntity, AccountDetailsErrorEntity>)
    private let miscFlagsResult: Result<Void, AccountErrorEntity>
    private let isUpgradeSecuritySuccess: Bool
    private let _bandwidthOverquotaDelay: Int64
    private let _currentUser: UserEntity?
    private let _isGuest: Bool
    private let _isNewAccount: Bool
    private let _isLoggedIn: Bool
    private let _contacts: [UserEntity]
    private let _currentAccountDetails: AccountDetailsEntity?
    private let _isOverQuota: Bool

    public init(currentUser: UserEntity? = UserEntity(handle: .invalid),
                isGuest: Bool = false,
                isNewAccount: Bool = false,
                isLoggedIn: Bool = true,
                contacts: [UserEntity] = [],
                totalNodesCountVariable: UInt64 = 0,
                getMyChatFilesFolderResult: Result<NodeEntity, AccountErrorEntity> = .failure(.nodeNotFound),
                currentAccountDetails: AccountDetailsEntity? = nil,
                accountDetailsResult: Result<AccountDetailsEntity, AccountDetailsErrorEntity> = .failure(.generic),
                miscFlagsResult: Result<Void, AccountErrorEntity> = .failure(.generic),
                isUpgradeSecuritySuccess: Bool = false,
                bandwidthOverquotaDelay: Int64 = 0,
                isOverQuota: Bool = false
    ) {
        _currentUser = currentUser
        _isGuest = isGuest
        _isNewAccount = isNewAccount
        _isLoggedIn = isLoggedIn
        _contacts = contacts
        _currentAccountDetails = currentAccountDetails
        _bandwidthOverquotaDelay = bandwidthOverquotaDelay
        _isOverQuota = isOverQuota
        self.totalNodesCountVariable = totalNodesCountVariable
        self.getMyChatFilesFolderResult = getMyChatFilesFolderResult
        self.accountDetailsResult = accountDetailsResult
        self.isUpgradeSecuritySuccess = isUpgradeSecuritySuccess
        self.miscFlagsResult = miscFlagsResult
    }
    
    public var currentUserHandle: HandleEntity? {
        _currentUser?.handle
    }
    
    public func currentUser() async -> UserEntity? {
        _currentUser
    }
    
    public var isGuest: Bool {
        _isGuest
    }
    
    public var isNewAccount: Bool {
        _isNewAccount
    }
    
    public func isLoggedIn() -> Bool {
        _isLoggedIn
    }
    
    public func contacts() -> [UserEntity] {
        _contacts
    }
    
    public var bandwidthOverquotaDelay: Int64 {
        _bandwidthOverquotaDelay
    }
    
    public func totalNodesCount() -> UInt64 {
        totalNodesCountVariable
    }
    
    public func getMyChatFilesFolder(completion: @escaping (Result<NodeEntity, AccountErrorEntity>) -> Void) {
        completion(getMyChatFilesFolderResult)
    }
    
    public var currentAccountDetails: AccountDetailsEntity? {
        _currentAccountDetails
    }

    public var isOverQuota: Bool {
        _isOverQuota
    }

    public func refreshCurrentAccountDetails() async throws -> AccountDetailsEntity {
        switch accountDetailsResult {
        case .success(let details): return details
        case .failure(let error): throw error
        }
    }
    
    public func upgradeSecurity() async throws -> Bool {
        isUpgradeSecuritySuccess
    }
    
    public func getMiscFlags() async throws {
        if case .failure(let error) = miscFlagsResult {
            throw error
        }
    }
}
