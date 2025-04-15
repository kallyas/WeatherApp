import SwiftUI

struct FogEffectView: View {
    let isDarkMode: Bool
    
    var body: some View {
        ZStack {
            ForEach(0..<5) { i in
                FogCloud(opacity: 0.2, isDarkMode: isDarkMode, index: i)
            }
        }
    }
}

struct FogCloud: View {
    let opacity: Double
    let isDarkMode: Bool
    let index: Int
    
    @State private var offsetY: CGFloat = 0
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        isDarkMode ? Color.black.opacity(0) : Color.white.opacity(0),
                        isDarkMode ? Color.black.opacity(opacity) : Color.white.opacity(opacity),
                        isDarkMode ? Color.black.opacity(opacity) : Color.white.opacity(opacity),
                        isDarkMode ? Color.black.opacity(0) : Color.white.opacity(0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(height: 150)
            .offset(y: offsetY + CGFloat(index * 150))
            .onAppear {
                let baseOffset = UIScreen.main.bounds.height
                offsetY = baseOffset
                
                withAnimation(
                    Animation
                        .linear(duration: 100)
                        .repeatForever(autoreverses: true)
                ) {
                    offsetY = baseOffset - 300
                }
            }
    }
}
