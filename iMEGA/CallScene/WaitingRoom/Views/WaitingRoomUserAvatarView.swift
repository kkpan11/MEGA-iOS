import MEGADesignToken
import SwiftUI

struct WaitingRoomUserAvatarView: View {
    let avatar: Image

    var body: some View {
        avatar
            .resizable()
            .scaledToFill()
            .frame(width: 80, height: 80)
            .clipShape(Circle())
            .padding(2)
            .overlay(
                Circle()
                    .stroke(
                        Color(.whiteFFFFFF).opacity(0.3),
                        lineWidth: 4
                    )
            )
    }
}

#Preview {
    WaitingRoomUserAvatarView(avatar: Image(Color.red, CGSize(width: 100, height: 100)))
        .padding(20)
        .background(Color(.black000000))
        .previewLayout(.sizeThatFits)
}
