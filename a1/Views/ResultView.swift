import SwiftUI

struct ResultView: View {
    let figure: HistoricalFigure

    private let controller = FiguresController.shared

    var body: some View {
        let margaretThatcher = controller.figure(withID: "margaret-thatcher", fallback: figure)
        let daVinci = controller.figure(withID: "da-vinci", fallback: figure)

        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                Text("Result")
                    .font(.h1PageTitle)
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
                    PortraitImage(imageName: figure.imageName)
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
                            .frame(width: .infinity, height: 35)
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
                        HStack(spacing: 8) {
                            Text(figure.name)
                                .font(.h1PageTitle)
                                            .tracking(1.1)
                                .foregroundStyle(.white)

                            Text(figure.flag)
                                .font(.system(size: 18))
                        }
                        .offset(x: 0, y: -50)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                    }
                    
                    Text(figure.summary)
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
                        Text("87 years")
                            .font(Font.custom("Inter", size: 14).weight(.medium))
                            .foregroundColor(.black)
                            .offset(x: 20, y: -35)
                    }
            
                        
                       
                        Text(figure.role)
                            .font(Font.custom("Inter", size: 14).weight(.medium))
                            .foregroundColor(.black)
                            .offset(x: 25, y: -30)
                 

                    Text("Contemporaries")
                        .font(.h1SectionTitle)
                            .tracking(1.1)
                        .foregroundStyle(Color.tealButton)
                }

                NavigationLink {
                    LifespanCompareView(firstFigure: margaretThatcher, secondFigure: daVinci)
                } label: {
                    HStack(spacing: 10) {
                        PortraitImage(imageName: daVinci.imageName)
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                        VStack(alignment: .leading, spacing: 3) {
                            Text(daVinci.name)
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
        .h1NavigationTitle("Result")
    }
}
