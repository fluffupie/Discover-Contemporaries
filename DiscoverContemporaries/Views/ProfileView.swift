import SwiftUI

struct ProfileView: View {
    let figure: HistoricalFigure

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                ZStack {
                    Image("frame")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 230, height: 230)
                        .offset(y: -25)

                    PortraitImage(imageURL: figure.imageURL)
                        .frame(width: 140, height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .shadow(color: .black.opacity(0.2), radius: 12, y: 7)
                        .offset(y: -25)
                }
                .frame(width: 230, height: 230)

                VStack(alignment: .leading, spacing: 6) {
                    FigureIdentityBanner(figure: figure)
                        .offset(y: -50)

                    Text(figure.description ?? "No description available yet.")
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

                    RolePill(label: figure.region ?? "Historical figure")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .offset(y: -30)

                    Text("Contemporaries")
                        .font(.h1SectionTitle)
                        .tracking(1.1)
                        .foregroundColor(.emerald)
                        .offset(x: 5)
                }

                // TODO: Populate this from Wikidata lifespan data once contemporaries discovery is implemented.
                Text("Contemporaries discovery is not implemented for Wikidata figures yet.")
                    .font(.caption)
                    .foregroundStyle(Color.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 6))

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

            VStack(alignment: .leading, spacing: 3) {
                Text(figure.name.uppercased())
                    .font(.system(size: 20, weight: .regular, design: .serif))
                    .tracking(1.2)
                    .foregroundStyle(Color.primaryText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                    .multilineTextAlignment(.leading)

                if let region = figure.region {
                    Text(region)
                        .font(.caption)
                        .foregroundStyle(Color.secondaryText)
                        .lineLimit(1)
                }
            }
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
    let label: String

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "sparkle")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.ochre.opacity(0.78))

            Text(label.uppercased())
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
