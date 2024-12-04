@testable import CloudDrive
import Combine
import Testing

@Suite("ManageTagsViewModel Tests")
struct ManageTagsViewModelTests {
    
    @MainActor
    @Test(
        "Verify tagNameState updates based on tagName input",
        arguments: [
            ("", "", ManageTagsViewModel.TagNameState.empty),
            ("#", "", ManageTagsViewModel.TagNameState.empty),
            ("#test", "test", ManageTagsViewModel.TagNameState.valid),
            ("####test", "test", ManageTagsViewModel.TagNameState.valid),
            ("####test#", "test#", ManageTagsViewModel.TagNameState.invalid),
            ("####test#again", "test#again", ManageTagsViewModel.TagNameState.invalid),
            ("Tag1", "tag1", ManageTagsViewModel.TagNameState.valid),
            ("tag1", "", ManageTagsViewModel.TagNameState.valid),
            ("invalid@tag!", "", ManageTagsViewModel.TagNameState.invalid),
            (String(repeating: "a", count: 33), "", ManageTagsViewModel.TagNameState.tooLong)
        ]
    )
    func validateAndUpdateTagNameState(updatedTagName: String, expectedTagName: String, expectedState: ManageTagsViewModel.TagNameState) async {
        let viewModel = makeSUT()
        viewModel.tagName = ""
        viewModel.onTagNameChanged(with: updatedTagName)
        #expect(viewModel.tagName == expectedTagName)
        #expect(viewModel.tagNameState == expectedState)
    }
    
    @MainActor
    @Test(
        "Verify addTag only adds valid tag names and clears tagName",
        arguments: [
            ("tag1", true, false),
            ("invalid@tag!", false, false)
        ]
    )
    func verifyAddTag(
        updatedTagName: String,
        containsTag: Bool,
        canAddNewTag: Bool
    ) {
        let viewModel = makeSUT()

        // Set the initial tag name and add it
        viewModel.tagName = updatedTagName
        viewModel.onTagNameChanged(with: updatedTagName)
        viewModel.addTag()

        // Expectation checks
        #expect(viewModel.existingTagsViewModel.containsTags == containsTag)
        #expect(viewModel.containsExistingTags == containsTag)
        #expect(viewModel.canAddNewTag == canAddNewTag)
    }

    @MainActor
    @Test("Verify clear text field")
    func verifyClearTextField() {
        let viewModel = makeSUT()

        let initialTagName = "Initial Tag Name"
        viewModel.tagName = initialTagName
        #expect(viewModel.tagName == initialTagName)
        viewModel.clearTextField()
        #expect(viewModel.tagName == "")
    }

    @MainActor
    @Test(
        "Verify loading all the tags from the account",
        arguments: [
            ([], false),
            (["tag1"], true)
        ]
    )
    func verifyLoadAllTags(tags: [String], containsExistingTags: Bool) async {
        let sut = makeSUT(nodeSearcher: MockNodeTagsSearcher(tags: tags))
        #expect(sut.containsExistingTags == false)
        await sut.loadAllTags()
        #expect(sut.containsExistingTags == containsExistingTags)
    }

    @MainActor
    @Test("test", arguments: [
        (nil, true),
        (["test"], false)
    ])
    func verifyCanAddNewTags(result: [String]?, expectedCanAddNewTag: Bool) async {
        let nodeSearcher = MockNodeTagsSearcher(tags: nil)
        let sut = makeSUT(nodeSearcher: nodeSearcher)
        sut.tagName = "test"
        sut.onTagNameChanged(with: "test")
        while await nodeSearcher.continuation == nil {
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
        await nodeSearcher.continuation?.resume(with: .success(result))
        for await canAddNewTag in sut.$canAddNewTag.dropFirst().values {
            #expect(canAddNewTag == expectedCanAddNewTag)
            break
        }
    }

    @MainActor
    private func makeSUT(nodeSearcher: some NodeTagsSearching = MockNodeTagsSearcher()) -> ManageTagsViewModel {
        ManageTagsViewModel(
            navigationBarViewModel: ManageTagsViewNavigationBarViewModel(doneButtonDisabled: .constant(true)),
            existingTagsViewModel: ExistingTagsViewModel(
                tagsViewModel: NodeTagsViewModel(tagViewModels: []),
                nodeTagSearcher: nodeSearcher,
                isSelectionEnabled: false
            )
        )
    }
}