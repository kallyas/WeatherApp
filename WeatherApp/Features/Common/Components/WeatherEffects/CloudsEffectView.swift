import SwiftUI

struct CloudsEffectView: View {
    let isDarkMode: Bool
    
    var body: some View {
        ZStack {
            ForEach(0..<10) { i in
                CloudView(size: CGFloat.random(in: 100...300), opacity: 0.7, isDarkMode: isDarkMode)
                    .offset(x: CGFloat.random(in: -UIScreen.main.bounds.width/2...UIScreen.main.bounds.width/2),
                            y: CGFloat.random(in: -200...UIScreen.main.bounds.height))
            }
        }
    }
}

struct CloudView: View {
    let size: CGFloat
    let opacity: Double
    let isDarkMode: Bool
    
    @State private var offset: CGFloat = 0
    
    var body: some View {
        Image(systemName: "cloud.fill")
            .resizable()
            .frame(width: size, height: size * 0.6)
            .foregroundColor(isDarkMode ? Color.white.opacity(0.1) : Color.white.opacity(opacity))
            .offset(x: offset, y: 0)
            .onAppear {
                withAnimation(Animation.linear(duration: Double.random(in: 60...120)).repeatForever(autoreverses: false)) {
                    offset = UIScreen.main.bounds.width + size
                }
            }
    }
}
