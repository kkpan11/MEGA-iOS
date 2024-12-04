import MEGASwift

public protocol RubbishBinSettingsUseCaseProtocol: Sendable {
    var onRubbishBinSettinghsRequestFinish: AnyAsyncSequence<Result<RubbishBinSettingsEntity, any Error>> { get }
}

public struct RubbishBinSettingsUseCase<R: RubbishBinSettingsRepositoryProtocol>: RubbishBinSettingsUseCaseProtocol {
    private let rubbishBinSettingsRepository: R
    
    public var onRubbishBinSettinghsRequestFinish: AnyAsyncSequence<Result<RubbishBinSettingsEntity, any Error>> {
        rubbishBinSettingsRepository.onRubbishBinSettinghsRequestFinish
    }
    
    public init(rubbishBinSettingsRepository: R) {
        self.rubbishBinSettingsRepository = rubbishBinSettingsRepository
    }
}