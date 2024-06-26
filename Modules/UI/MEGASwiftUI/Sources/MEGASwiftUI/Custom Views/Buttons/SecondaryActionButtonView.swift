import MEGADesignToken
import SwiftUI

public struct SecondaryActionButtonView: View {
    private let title: String
    private let action: (() -> Void)
    
    @Environment(\.colorScheme) var colorScheme
    private var textColor: Color {
        colorScheme == .dark ? Color(red: 0, green: 0.76, blue: 0.60) : Color(red: 0, green: 0.65, blue: 0.52)
    }
    
    private var background: Color {
        colorScheme == .dark ? Color(red: 0.21, green: 0.21, blue: 0.22) : Color.white
    }
    
    public init(title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.accent.swiftUI : textColor)
                .font(.title3)
                .background(isDesignTokenEnabled ? TokenColors.Button.secondary.swiftUI : background)
                .cornerRadius(10)
                .contentShape(Rectangle())
        }
        .shadow(color: isDesignTokenEnabled ? .clear : Color.black.opacity(0.15), radius: 4, y: 1) // Shadow should be removed when design token is permanently applied as it won't be needed.
    }
}
