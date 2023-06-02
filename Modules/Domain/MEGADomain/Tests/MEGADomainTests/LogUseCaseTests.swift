import XCTest
import MEGADomain
import MEGADomainMock

final class LogUseCaseTests: XCTestCase {
    func testShouldEnableLogs_debuggingEnabledByTheUser_shouldReturnTrue() {
        let preference = MockPreferenceUseCase(dict: [.logging: true])
        let appConfig = MockAppEnvironmentUseCase(configuration: .debug)
        let sut = LogUseCase(preferenceUseCase: preference, appEnvironment: appConfig)

        XCTAssertTrue(sut.shouldEnableLogs())
    }
    
    func testShouldEnableLogs_debuggingNotEnabledByTheUser_shouldReturnFalse() {
        let preference = MockPreferenceUseCase(dict: [.logging: false])
        let appConfig = MockAppEnvironmentUseCase(configuration: .debug)
        let sut = LogUseCase(preferenceUseCase: preference, appEnvironment: appConfig)

        XCTAssertFalse(sut.shouldEnableLogs())
    }
    
    func testShouldEnableLogs_appInProductionEnabledByTheUser_shouldReturnTrue() {
        let preference = MockPreferenceUseCase(dict: [.logging: true])
        let appConfig = MockAppEnvironmentUseCase(configuration: .production)
        let sut = LogUseCase(preferenceUseCase: preference, appEnvironment: appConfig)

        XCTAssertTrue(sut.shouldEnableLogs())
    }
    
    func testShouldEnableLogs_appInProductionNotEnabledByTheUser_shouldReturnFalse() {
        let preference = MockPreferenceUseCase(dict: [.logging: false])
        let appConfig = MockAppEnvironmentUseCase(configuration: .production)
        let sut = LogUseCase(preferenceUseCase: preference, appEnvironment: appConfig)

        XCTAssertFalse(sut.shouldEnableLogs())
    }
    
    func testShouldEnableLogs_appInQA_shouldReturnTrue() {
        let preference = MockPreferenceUseCase(dict: [.logging: false])
        let appConfig = MockAppEnvironmentUseCase(configuration: .qa)
        let sut = LogUseCase(preferenceUseCase: preference, appEnvironment: appConfig)

        XCTAssertTrue(sut.shouldEnableLogs())
    }
    
    func testShouldEnableLogs_appInTestFlight_shouldReturnTrue() {
        let preference = MockPreferenceUseCase(dict: [.logging: false])
        let appConfig = MockAppEnvironmentUseCase(configuration: .testFlight)
        let sut = LogUseCase(preferenceUseCase: preference, appEnvironment: appConfig)
        XCTAssertTrue(sut.shouldEnableLogs())
    }
}
