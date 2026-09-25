import SwiftUI

struct ProfileView: View {
    let figure: HistoricalFigure

    private let controller = FiguresController.shared

    var body: some View {
        let contemporaryFigures = controller.contemporaries(for: figure)
        let featuredContemporary = contemporaryFigures.first

        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                ZStack {
                    Image("frame")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 230, height: 230)
                        .offset(y: -25)
                    PortraitImage(imageName: figure.imageName)
                        .frame(width: 140, height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .shadow(color: .black.opacity(0.2), radius: 12, y: 7)
                        .offset(y: -25)
                }
                .frame(width: 230, height: 230)

                VStack(alignment: .leading, spacing: 6) {
                    FigureIdentityBanner(figure: figure)
                        .offset(y: -50)
                    
                    Text(figure.summary)
                        .font(.system(.body, design: .serif))
                        .foregroundColor(.black)
                        .offset(x: 5, y: -45)

                    HStack {
                        Text(figure.lifespan)
                            .font(Font.custom("AlegreyaSansSC-Regular", size: 16))
                            .foregroundColor(.black)
                            .offset(x: 5, y: -30)
                        Ellipse()
                            .foregroundColor(.clear)
                            .frame(width: 5, height: 5)
                            .background(Color(red: 0.62, green: 0.11, blue: 0.14))
                            .offset(x: 15, y: -30)
                        Text(figure.ageText)
                            .font(Font.custom("AlegreyaSansSC-Regular", size: 16))
                            .foregroundColor(.black)
                            .offset(x: 20, y: -30)
                    }
                    RolePill(role: figure.role)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .offset(y: -30)

                    Text("Contemporaries")
                        .font(.h1SectionTitle)
                            .tracking(1.1)
                            .foregroundColor(.emerald)
                        .offset(x: 5)
                }

                if let featuredContemporary {
                    NavigationLink {
                        LifespanCompareView(firstFigure: figure, secondFigure: featuredContemporary)
                    } label: {
                        HStack(spacing: 10) {
                            PortraitImage(imageName: featuredContemporary.imageName)
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 6))

                            VStack(alignment: .leading, spacing: 3) {
                                Text(featuredContemporary.name)
                                    .foregroundStyle(Color.primaryText)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color.secondaryText)
                        }
                        .padding(10)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("No overlapping lifespans in the current data.")
                        .font(.caption)
                        .foregroundStyle(Color.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                NavigationLink {
                    ContemporariesView(figure: figure)
                } label: {
                    Text("See all")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.tealButton)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 30)
        }
        .background(Color.appBackground)
        .h1NavigationTitle("Profile")
    }
}

private struct FigureIdentityBanner: View {
    let figure: HistoricalFigure

    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color.ochre)
                .frame(width: 3)
                .clipShape(Capsule())

            Text(figure.name.uppercased())
                .font(.system(size: 20, weight: .regular, design: .serif))
                .tracking(1.2)
                .foregroundStyle(Color.primaryText)
                .lineLimit(2)
                .minimumScaleFactor(0.82)
                .multilineTextAlignment(.leading)

            Text(figure.flag)
                .font(.system(size: 26))
                .lineLimit(1)
                .accessibilityLabel("Country flag")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
        .background(Color.white.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.ochre.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
}

private struct RolePill: View {
    let role: String

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "sparkle")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.ochre.opacity(0.78))

            Text(role.uppercased())
                .font(Font.custom("AlegreyaSansSC-Regular", size: 15).weight(.medium))
                .tracking(1.1)
                .foregroundStyle(Color.ochre)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.62))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.ochre.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.035), radius: 5, x: 0, y: 2)
        .accessibilityElement(children: .combine)
    }
}

