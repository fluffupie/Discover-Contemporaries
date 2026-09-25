import SwiftUI

struct SettingsView: View {
    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Notifications")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.primaryText)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.secondaryText)
                }

                Divider()

                HStack {
                    Text("Appearance")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.primaryText)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.secondaryText)
                }
            }
            .padding(14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .background(Color.appBackground)
        .h1NavigationTitle("Settings")
    }
}
