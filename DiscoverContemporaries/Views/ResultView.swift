import SwiftUI

struct ResultView: View {
    let figure: HistoricalFigure
    
    private var ageText: String {
        guard let birth = figure.birthDate else { return "Unknown age" }
        let end = figure.deathDate ?? Date()
        let years = Calendar.current.dateComponents([.year], from: birth, to: end).year ?? 0
        return years == 1 ? "1 year" : "\(years) years"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                Text("Result")
                    .font(.title)
                    .tracking(1.2)
                    .lineSpacing(24)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .offset(x: 0, y: -50)
                
                PortraitImage(imageName: figure.imageName, imageURL: figure.imageURL)
                    .frame(width: 150, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: .black.opacity(0.18), radius: 12, y: 7)
                    .frame(maxWidth: .infinity, alignment: .center)
                
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
                            .font(.title)
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
                        Text(ageText)
                            .font(Font.custom("Inter", size: 14).weight(.medium))
                            .foregroundColor(.black)
                            .offset(x: 20, y: -35)
                    }
                    
                    Text(figure.occupations.first ?? figure.birthPlace ?? "Historical figure")
                        .font(Font.custom("Inter", size: 14).weight(.medium))
                        .foregroundColor(.black)
                        .offset(x: 25, y: -30)
                    
                    Text("Contemporaries")
                        .font(.title)
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
