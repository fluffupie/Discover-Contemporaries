import SwiftUI

struct ResultView: View {
    let figure: HistoricalFigure

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                Text("Result")
                    .font(.h1Title)
                    .tracking(1.2)
                    .lineSpacing(24)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .offset(x: 0, y: -50)
                
                ZStack {
                    Image("frame")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 220, height: 220)
                        .offset(x: 65, y: -40)
                    PortraitImage(imageURL: figure.imageURL)
                        .frame(width: 138, height: 138)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .shadow(color: .black.opacity(0.2), radius: 12, y: 7)
                        .offset(x: 65, y: -50)
                }
                .frame(width: 220, height: 220)
                
                VStack(alignment: .leading, spacing: 6) {
                    ZStack {
                        Rectangle()
                            .foregroundColor(.clear)
                            .frame(maxWidth: .infinity)
                            .frame(height: 35)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 194 / 255, green: 49 / 255, blue: 49 / 255),
                                        Color(red: 226 / 255, green: 158 / 255, blue: 162 / 255)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(3)
                            .offset(x: 0, y: -50)
                        Text(figure.name)
                            .font(.h1Title)
                            .tracking(1.1)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .offset(x: 0, y: -50)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                    }
                    
                    Text(figure.descriptionText ?? "No description available yet.")
                        .font(Font.custom("Inter", size: 14).weight(.medium))
                        .foregroundColor(.black)
                        .offset(x: 5, y: -30)
                    
                    HStack {
                        Text(figure.lifespan)
                            .foregroundColor(.black)
                            .offset(x: 5, y: -35)
                        Ellipse()
                            .foregroundColor(.clear)
                            .frame(width: 5, height: 5)
                            .background(Color(red: 0.62, green: 0.11, blue: 0.14))
                            .offset(x: 15, y: -35)
                        Text(figure.ageText)
                            .font(Font.custom("Inter", size: 14).weight(.medium))
                            .foregroundColor(.black)
                            .offset(x: 20, y: -35)
                    }
                    
                    Text(figure.occupations.first ?? figure.country ?? "Historical figure")
                        .font(Font.custom("Inter", size: 14).weight(.medium))
                        .foregroundColor(.black)
                        .offset(x: 25, y: -30)
                    
                    Text("Contemporaries")
                        .font(.h1Title)
                        .tracking(1.1)
                        .foregroundStyle(Color.tealButton)
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
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.tealButton)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 28)
        }
        .background(Color.appBackground)
        .navigationTitle("Result")
        .navigationBarTitleDisplayMode(.inline)}
}
