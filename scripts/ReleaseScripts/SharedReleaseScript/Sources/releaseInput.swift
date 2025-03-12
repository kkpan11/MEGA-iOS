public struct ReleaseInput {
    public let version: String
    public let message: String
}

public func releaseInput() throws -> ReleaseInput {
    let versionFetcher = VersionFetcher()
    let defaultVersion = try versionFetcher.fetchVersion()
    let version = try versionInput(defaultVersion: defaultVersion)

    let message = try releaseNotesInput(defaultReleaseNotes: defaultReleaseNotesInput())
    return .init(version: version, message: message)
}

public func defaultReleaseNotesTemplate(
    sdkVersion: String,
    chatVersion: String
) -> String {
    """
    Bug fixes and performance improvements.
    - SDK release - \(sdkVersion)
    - MEGAChat release - \(chatVersion)
    """
}

private func defaultReleaseNotesInput() throws -> String {
    print("Fetching the SDK and Chat branch names")
    let sdkVersion = try branchNameForSubmodule(with: Submodule.sdk.path)
    let chatVersion = try branchNameForSubmodule(with: Submodule.chatSDK.path)
    print("SDK: \(sdkVersion) \t Chat SDK: \(chatVersion)")

    return defaultReleaseNotesTemplate(sdkVersion: sdkVersion, chatVersion: chatVersion)
}

private func versionInput(defaultVersion: String) throws -> String {
    print("Is it for version \"\(defaultVersion)\" ? (yes/no)")

    guard let input = readLine() else {
        throw InputError.missingInput
    }

    let matchesYes = try matchesYes(input)
    let matchesNo = try matchesNo(input)

    switch input {
    case input where matchesYes:
        return try defaultVersion
    case input where matchesNo:
        return try majorMinorOrMajorMinorPatchInput(
            "Enter the version number you're releasing (format: '[major].[minor]' or '[major].[minor].[patch]')"
        )
    default:
        throw InputError.wrongInput
    }
}
