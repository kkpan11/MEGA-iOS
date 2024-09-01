import MEGADesignToken
import MEGAL10n
import SwiftUI

struct NewChatRoomsEmptyCenterView: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    let state: ChatRoomsEmptyCenterViewState
    
    var body: some View {
        VStack {
            if verticalSizeClass != .compact {
                Image(state.image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .tint(TokenColors.Icon.secondary.swiftUI)
            }
            
            Text(state.title)
                .font(.body.bold())
                .padding(.bottom, 5)
                .foregroundColor(TokenColors.Text.primary.swiftUI)
            
            if let description = state.description {
                TaggableText(
                    description,
                    underline: true,
                    tappable: true,
                    linkColor: { _ in TokenColors.Text.secondary }
                )
                .multilineTextAlignment(.center)
                // line below is needed for tappable link to work
                    .textSelection(.enabled)
                    .multilineTextAlignment(.center)
                    .environment(\.openURL, OpenURLAction { _ in
                        state.linkTapped?()
                        return .handled
                    })
                    .font(.callout)
                    .tint(TokenColors.Text.secondary.swiftUI)
                    .foregroundColor(TokenColors.Text.secondary.swiftUI)
            }
        }
    }
}