import MEGADomain
import MEGAL10n
import MEGASwiftUI
import Search
import SwiftUI

struct NodeBrowserView: View {
    
    @StateObject var viewModel: NodeBrowserViewModel

    var body: some View {
        switch viewModel.viewState {
        case .editing:
            content
                .toolbar { toolbarContentEditing }
        case .regular(let isBackButtonShown):
            if isBackButtonShown {
                content
                    .toolbar { toolbarContent }
            } else {
                content
                   .toolbar { toolbarContentWithLeadingAvatar }
            }
        }
    }

    private var content: some View {
        VStack {
            if let warningViewModel = viewModel.warningViewModel {
                WarningView(viewModel: warningViewModel)
            }
            if let mediaDiscoveryViewModel = viewModel.viewModeAwareMediaDiscoveryViewModel {
                MediaDiscoveryContentView(viewModel: mediaDiscoveryViewModel)
            } else {
                SearchResultsView(viewModel: viewModel.searchResultsViewModel)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.onViewAppear() }
        .onLoad { viewModel.onLoadTask() }
    }

    @ToolbarContentBuilder
    private var toolbarContentEditing: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(
                action: { viewModel.selectAll() },
                label: { Image(.selectAllItems) }
            )
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button(Strings.Localizable.cancel) { viewModel.stopEditing() }
        }

        ToolbarItem(placement: .principal) {
            Text(viewModel.title).font(.headline)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        toolbarNavigationTitle
        toolbarTrailingNonEditingContent
    }

    @ToolbarContentBuilder
    private var toolbarContentWithLeadingAvatar: some ToolbarContent {
        toolbarLeadingAvatarImage
        toolbarNavigationTitle
        toolbarTrailingNonEditingContent
    }

    @ToolbarContentBuilder
    private var toolbarLeadingBackButton: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(
                action: { viewModel.back() },
                label: { Image(.backArrow) }
            )
        }
    }

    @ToolbarContentBuilder
    private var toolbarLeadingAvatarImage: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            MyAvatarIconView(
                viewModel: .init(
                    avatarObserver: viewModel.avatarViewModel,
                    onAvatarTapped: { viewModel.openUserProfile() }
                )
            )
        }
    }

    @ToolbarContentBuilder
    private var toolbarNavigationTitle: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text(viewModel.title)
                .font(.headline)
                .lineLimit(1)
        }
    }

    @ToolbarContentBuilder
    private var toolbarTrailingNonEditingContent: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            viewModel.contextMenuViewFactory?.makeAddMenuWithButtonView()
            viewModel.contextMenuViewFactory?.makeContextMenuWithButtonView()
        }
    }
}
